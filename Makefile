.PHONY: all upgrade restart

all: .installed.cfg

bin/pip:
	python3 -m venv . || virtualenv -p python3 --no-site-packages --no-setuptools . || virtualenv -p python3 --no-setuptools .

bin/buildout: bin/pip requirements.txt
	./bin/pip install -IUr requirements.txt

.installed.cfg: bin/buildout *.cfg
	./bin/buildout

upgrade:
	./bin/upgrade plone_upgrade -S &&  ./bin/upgrade install -Sp

restart:
	./bin/supervisord || ( ./bin/supervisorctl reread && ./bin/supervisorctl restart all)
