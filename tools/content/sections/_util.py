"""Small helpers shared by the Task 5c section modules."""


def clean(text) -> str:
    """Make a string safe for an entry line: no newline, no backtick."""
    return str(text).replace("\n", " ").replace("`", "'")


def group_ident(text) -> str:
    """A stable, lowercase ident for a group title."""
    return clean(text).lower().replace(" ", "_")
