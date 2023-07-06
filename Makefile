# In case your system doesn't have any of these tools:
# https://pypi.python.org/pypi/xml2rfc
# https://github.com/cabo/kramdown-rfc2629
# https://github.com/Juniper/libslax/tree/master/doc/oxtradoc
# https://tools.ietf.org/tools/idnits/

xml2rfc ?= xml2rfc
kramdown-rfc2629 ?= kramdown-rfc2629
oxtradoc ?= oxtradoc
idnits ?= idnits

draft := $(basename $(lastword $(sort $(wildcard draft-*.xml)) $(sort $(wildcard draft-*.md)) $(sort $(wildcard draft-*.org)) ))

ifeq (,$(draft))
$(warning No file named draft-*.md or draft-*.xml or draft-*.org)
$(error Read README.md for setup instructions)
endif

draft_type := $(suffix $(firstword $(wildcard $(draft).md $(draft).org $(draft).xml) ))

current_ver := $(shell git tag | grep '$(draft)-[0-9][0-9]' | tail -1 | sed -e"s/.*-//")
ifeq "${current_ver}" ""
next_ver ?= 00
else
next_ver ?= $(shell printf "%.2d" $$((1$(current_ver)-99)))
endif
next := $(draft)-$(next_ver)

.PHONY: latest submit clean

#latest: $(draft).txt $(draft).html

default: $(next).xml $(next).txt $(next).html

idnits: $(next).txt
	$(idnits) $<

clean:
	-rm -f $(draft)-[0-9][0-9].xml
	-rm -f $(draft)-[0-9][0-9].v2v3.xml
	-rm -f $(draft)-[0-9][0-9].txt
	-rm -f $(draft)-[0-9][0-9].html
	-rm -f ietf-*\@20*.yang
	-rm -f iana-*\@20*.yang
	-rm -f metadata.min.js
ifeq (md,$(draft_type))
	-rm -f $(draft).xml
endif
ifeq (org,$(draft_type))
	-rm -f $(draft).xml
endif

$(next).xml: $(draft).xml ietf-system-datastore.yang ietf-netconf-resolve-system.yang
	sed -e"s/$(basename $<)-latest/$(basename $@)/" -e"s/YYYY-MM-DD/$(shell date +%Y-%m-%d)/" $< > $@
	mkdir -p yang
	sed -e 's/YYYY-MM-DD/'$(shell date +%Y-%m-%d)'/g' ietf-system-datastore.yang | (cd yang && pyang --keep-comments -f yang >ietf-system-datastore@$(shell date +%Y-%m-%d).yang )
	sed -e 's/YYYY-MM-DD/'$(shell date +%Y-%m-%d)'/g' ietf-netconf-resolve-system.yang  > yang/ietf-netconf-resolve-system@$(shell date +%Y-%m-%d).yang 
#	cd refs && ./validate-all.sh && ./gen-trees.sh && cd ..
	chmod +x insert-figures.sh && ./insert-figures.sh $@ > tmp && mv tmp $@
#	rm refs/*-tree*.txt refs/tree-*.txt
	xml2rfc --v2v3 $@


.INTERMEDIATE: $(draft).xml
%.xml: %.md
	$(kramdown-rfc2629) $< > $@

%.xml: %.org
	$(oxtradoc) -m outline-to-xml -n "$@" $< > $@

%.txt: %.xml
	$(xml2rfc) --v3 $< -o $@ --text

%.html: %.xml
	$(xml2rfc) --v3 $< -o $@ --html


