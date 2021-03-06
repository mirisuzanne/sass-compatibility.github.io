#
# Executable to minify CSS.
#
UGLIFY = node_modules/uglifycss/uglifycss

#
# Find all tests (all directories one level under `tests`).
#
TESTS := $(shell find tests -mindepth 1 -maxdepth 1 -type d | sort)
TESTS := $(addsuffix /support.yml,$(TESTS))

#
# Sass engines to test.
#
ENGINES = 3.2 3.3 3.4 lib

#
# Output files for each engine (pattern matching).
#
OUTPUTS = $(addprefix tests/%/output.,$(addsuffix .css,$(ENGINES)))

all: _data/support.yml

#
# Remove cached intermediate files.
#
clean:
	find tests \
		\( \
			-name support.yml -o \
			-name output.*.css -o \
			-name expect.min.css \
		\) \
		-delete

#
# Run all tests and store results.
#
# The AWK trick is to add an empty line between each file.
#
_data/support.yml: $(TESTS)
	awk 'NR != 1 && FNR == 1 { print "" } 1' $^ > $@

# Tests {{{

#
# Run tests for each supported Sass compiler.
#
# The basename of the target directory will be used as YAML property,
# than all tests will be executed by comparing the input and the
# fixture (`$^` should contain the input file followed by the fixture).
#
# 1. True value.
# 2. False value.
#
# The boolean values are configurable so you can just invert them to run
# an "unexpect" test.
#
test = \
	basename $(@D) | sed 's/$$/:/' > $@; \
	utils/test ruby_sass_3_2 $(@D)/output.3.2.css $< $(1) $(2) >> $@; \
	utils/test ruby_sass_3_3 $(@D)/output.3.3.css $< $(1) $(2) >> $@; \
	utils/test ruby_sass_3_4 $(@D)/output.3.4.css $< $(1) $(2) >> $@; \
	utils/test libsass $(@D)/output.lib.css $< $(1) $(2) >> $@

#
# Test against an expected input (should equals).
#
tests/%/support.yml: tests/%/expect.min.css $(OUTPUTS)
	$(call test,true,false)

#
# Test against an unexpected input (should not equals).
#
tests/%/support.yml: tests/%/unexpect.min.css $(OUTPUTS)
	$(call test,false,true)

# }}}

# Compilation {{{
# ===============

#
# Do not remove compilation output (intermediate) files after execution.
#
.PRECIOUS: $(OUTPUTS)

tests/%/output.3.4.css: tests/%/input.scss
	utils/sm 3.4 $< > $@

tests/%/output.3.3.css: tests/%/input.scss
	utils/sm 3.3 $< > $@

tests/%/output.3.2.css: tests/%/input.scss
	utils/sm 3.2 $< > $@

tests/%/output.lib.css: tests/%/input.scss
	utils/sm lib $< > $@

# }}}

# Minification {{{
# ================

#
# Do not remove minified files after execution.
#
.PRECIOUS: tests/%.min.css

#
# How to create a `tests/%.min.css` from a `tests/%.css`.
#
# `$(UGLIFY)` should be built before, but it's not a real dependency
# (hence order-only prerequisite).
#
tests/%.min.css: tests/%.css | $(UGLIFY)
	$(UGLIFY) $< > $@

#
# Install CSS minifier.
#
$(UGLIFY):
	npm install uglifycss

# }}}
