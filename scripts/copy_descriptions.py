import sys

from transaction import commit


def copy_descriptions(target, source):
    num_handled = 0
    if (
        hasattr(source, "description")
        and source.description
        and hasattr(target, "description")
        and not target.description
    ):
        target.description = source.description
        num_handled += 1
    for sub_target, sub_source in zip(
        target.objectValues(),
        source.objectValues(),
    ):
        num_handled += copy_descriptions(sub_target, sub_source)
    return num_handled


if __name__ == "__main__":
    app = locals()["app"]
    real_tool = app.unrestrictedTraverse(sys.argv[3])
    translations_tool = app.unrestrictedTraverse(sys.argv[4])
    num_handled = copy_descriptions(real_tool, translations_tool)
    print(f"Handled {num_handled} descriptions")
    commit()
