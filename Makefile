OSHA_OIRA_POT	= src/osha.oira/src/osha/oira/locales/euphorie.pot
OSHA_OIRA_PO_FILES	= $(wildcard src/osha.oira/src/osha/oira/locales/*/LC_MESSAGES/euphorie.po)
EUPHORIE_POT	= src/Euphorie/src/euphorie/deployment/locales/euphorie.pot
EUPHORIE_PO_FILES	= $(wildcard src/Euphorie/src/euphorie/deployment/locales/*/LC_MESSAGES/euphorie.po)
.PHONY: all upgrade restart

all: .installed.cfg

py3/bin/pip:
	python3 -m venv py3 || virtualenv -p python3 --no-site-packages --no-setuptools py3 || virtualenv -p python3 --no-setuptools py3

py3/bin/buildout: py3/bin/pip requirements.txt
	./py3/bin/pip uninstall -y setuptools
	./py3/bin/pip install -IUr requirements.txt

.installed.cfg: py3/bin/buildout *.cfg
	./py3/bin/buildout

upgrade:
	./bin/upgrade plone_upgrade -S &&  ./bin/upgrade install -Sp

restart:
	./bin/supervisord || ( ./bin/supervisorctl reread && ./bin/supervisorctl restart all)

pot:
	i18ndude rebuild-pot --exclude="generated prototype examples illustrations help" --pot $(EUPHORIE_POT) src/Euphorie/src/euphorie --create euphorie
	$(MAKE) $(MFLAGS) $(EUPHORIE_PO_FILES)
	i18ndude rebuild-pot --exclude="generated prototype examples" --pot $(OSHA_OIRA_POT) src/osha.oira/src/osha/oira --create euphorie
	$(MAKE) $(MFLAGS) $(OSHA_OIRA_PO_FILES)

$(EUPHORIE_PO_FILES): $(EUPHORIE_POT)
	msgmerge --update -N --lang `echo $@ | awk -F"/" '{print ""$$5}'` $@ $<

$(OSHA_OIRA_PO_FILES): $(OSHA_OIRA_POT)
	msgmerge --update -N --lang `echo $@ | awk -F"/" '{print ""$$5}'` $@ $<

.PHONY: read_registry
read_registry: .installed.cfg
	./bin/instance run scripts/read_registry.py etc/registry/*.xml
