def parse_index_ranges(
    raw: str,
    item_count: int,
    *,
    missing_label: str = "Pozycja",
    empty_message: str = "Nie wybrano żadnego wyposażenia.",
) -> list[int]:
    """Parse comma-separated 1-based indexes and inclusive ranges.

    The returned indexes are zero-based and retain the order entered by the
    player. Duplicate indexes are rejected to keep bulk operations atomic.
    """
    text = raw.strip()
    if not text:
        raise ValueError("Nie podano żadnego wyboru.")

    indexes: list[int] = []
    selected: set[int] = set()
    for chunk in text.split(","):
        part = chunk.strip()
        if not part:
            continue

        numbers = _parse_range(part)
        for number in numbers:
            if not 1 <= number <= item_count:
                raise ValueError(f"{missing_label} [{number}] nie istnieje.")

            index = number - 1
            if index in selected:
                raise ValueError(
                    f"{missing_label} [{number}] został wybrany więcej niż raz."
                )
            selected.add(index)
            indexes.append(index)

    if not indexes:
        raise ValueError(empty_message)
    return indexes


def _parse_range(part: str) -> range | tuple[int]:
    if "-" not in part:
        return (int(part),)

    start_text, end_text = part.split("-", maxsplit=1)
    try:
        start = int(start_text.strip())
        end = int(end_text.strip())
    except ValueError as error:
        raise ValueError(f"Nieprawidłowy zakres: {part}.") from error
    if end < start:
        raise ValueError(f"Nieprawidłowy zakres: {part}.")
    return range(start, end + 1)
