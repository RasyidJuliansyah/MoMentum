"""Daftar provider yang bisa dipilih dari CLI."""
from .assemblyai import AssemblyAIProvider
from .soniox import SonioxProvider
from .speechmatics import SpeechmaticsProvider

PROVIDERS = {
    p.name: p for p in (AssemblyAIProvider, SonioxProvider, SpeechmaticsProvider)
}
