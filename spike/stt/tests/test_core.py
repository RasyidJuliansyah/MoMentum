import argparse

import pytest

from stt_spike import cli
from stt_spike.base import ProviderError, Token, TranscriptResult, Utterance, merge_tokens, poll
from stt_spike.providers.soniox import tokens_to_utterances
from stt_spike.providers.speechmatics import results_to_utterances
from stt_spike.report import fmt_time, summary_markdown
from stt_spike.wer import wer


def test_merge_tokens_groups_consecutive_speakers():
    toks = [
        Token("A", 0, 500, "Halo"),
        Token("A", 500, 900, "semua"),
        Token("A", 900, 950, ".", no_space_before=True),
        Token("B", 1000, 1500, "Siap"),
        Token("A", 1600, 2000, "Oke"),
    ]
    utts = merge_tokens(toks)
    assert [(u.speaker, u.text) for u in utts] == [("A", "Halo semua."), ("B", "Siap"), ("A", "Oke")]
    assert utts[0].end_ms == 950


def test_soniox_tokens_keep_their_own_spacing():
    tokens = [
        {"text": "Ra", "start_ms": 0, "end_ms": 100, "speaker": "1"},
        {"text": "pat", "start_ms": 100, "end_ms": 200, "speaker": "1"},
        {"text": " dimulai", "start_ms": 200, "end_ms": 500, "speaker": "1"},
        {"text": " Baik", "start_ms": 600, "end_ms": 800, "speaker": "2"},
    ]
    utts = tokens_to_utterances(tokens)
    assert [(u.speaker, u.text) for u in utts] == [("1", "Rapat dimulai"), ("2", "Baik")]


def test_speechmatics_punctuation_attaches_to_previous_word():
    results = [
        {"type": "word", "start_time": 0.1, "end_time": 0.4, "alternatives": [{"content": "Deadline", "speaker": "S1"}]},
        {"type": "word", "start_time": 0.4, "end_time": 0.8, "alternatives": [{"content": "Jumat", "speaker": "S1"}]},
        {"type": "punctuation", "start_time": 0.8, "end_time": 0.8, "alternatives": [{"content": ".", "speaker": "S1"}]},
        {"type": "word", "start_time": 1.0, "end_time": 1.3, "alternatives": [{"content": "Setuju", "speaker": "S2"}]},
    ]
    utts = results_to_utterances(results)
    assert [(u.speaker, u.text, u.start_ms) for u in utts] == [("S1", "Deadline Jumat.", 100), ("S2", "Setuju", 1000)]


def test_wer_ignores_case_and_punctuation():
    assert wer("Rapat dimulai jam sembilan.", "rapat dimulai jam sembilan") == 0
    assert wer("satu dua tiga empat", "satu dua tiga") == pytest.approx(0.25)


def test_poll_returns_payload_when_done_and_raises_on_failure():
    states = iter([("queued", {}), ("processing", {}), ("completed", {"ok": True})])
    assert poll(lambda: next(states), {"completed"}, {"error"}, "t", sleep=lambda s: None) == {"ok": True}
    with pytest.raises(ProviderError):
        poll(lambda: ("error", {"error": "x"}), {"completed"}, {"error"}, "t", sleep=lambda s: None)
    with pytest.raises(ProviderError):
        poll(lambda: ("queued", {}), {"completed"}, {"error"}, "t", interval=5, timeout=10, sleep=lambda s: None)


def test_fmt_time_handles_hours():
    assert fmt_time(2 * 3600 * 1000 + 5 * 60 * 1000 + 7000) == "02:05:07"


def test_run_one_skips_without_key_and_saves_result(tmp_path, monkeypatch):
    class FakeProvider:
        name = "fake"
        env_key = "FAKE_KEY"

        def __init__(self, api_key, language, max_speakers):
            pass

        def transcribe(self, path):
            return TranscriptResult("fake", [Utterance("A", 0, 1000, "rapat dimulai")], 6.0, {})

    monkeypatch.setitem(cli.PROVIDERS, "fake", FakeProvider)
    audio = tmp_path / "meeting.m4a"
    audio.write_bytes(b"x")
    args = argparse.Namespace(language="id", max_speakers=None, out=str(tmp_path / "results"))

    monkeypatch.delenv("FAKE_KEY", raising=False)
    assert cli.run_one("fake", audio, args, None)["status"].startswith("dilewati")

    monkeypatch.setenv("FAKE_KEY", "k")
    row = cli.run_one("fake", audio, args, "rapat dimulai")
    assert row["status"] == "ok" and row["wer"] == 0
    assert (tmp_path / "results" / "meeting" / "fake.md").is_file()
    assert "| fake | ok |" in summary_markdown([row], "meeting.m4a")
