from dataclasses import dataclass, field


MAX_LOG_ENTRIES = 50


@dataclass
class AdventureLog:
    entries: list[str] = field(default_factory=list)

    def add(self, day: int, hour: int, message: str) -> None:
        self.entries.append(f"Dzień {day}, {hour:02d}:00 — {message}")
        if len(self.entries) > MAX_LOG_ENTRIES:
            del self.entries[:-MAX_LOG_ENTRIES]

    def recent(self, limit: int = 30) -> list[str]:
        return self.entries[-limit:]
