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

.PHONY: read_registry
read_registry: .installed.cfg
	./bin/instance run scripts/read_registry.py etc/registry/*.xml
