import sys

from plone.dexterity.utils import createContentInContainer
from transaction import commit
from zope.component.hooks import setSite


def add_missing_measures(target, source):
    num_handled = 0
    target_children = target.objectValues()
    source_children = source.objectValues()
    for sub_target, sub_source in zip(target_children, source_children):
        if sub_target.portal_type != "euphorie.solution":
            num_handled += add_missing_measures(sub_target, sub_source)
    for sub_source in source_children[len(target_children) :]:
        if sub_source.portal_type == "euphorie.solution":
            sub_target = createContentInContainer(target, "euphorie.solution")
            sub_target.description = sub_source.description
            sub_target.action = sub_source.action
            sub_target.action_plan = sub_source.action_plan
            sub_target.prevention_plan = sub_source.prevention_plan
            sub_target.requirements = sub_source.requirements
            num_handled += 1
    return num_handled


if __name__ == "__main__":
    app = locals()["app"]
    real_tool = app.unrestrictedTraverse(sys.argv[3])
    translations_tool = app.unrestrictedTraverse(sys.argv[4])
    setSite(real_tool.portal_url.getPortalObject())

    num_handled = add_missing_measures(real_tool, translations_tool)
    print(f"Handled {num_handled} measures")
    commit()
