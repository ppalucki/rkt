define multi-subst
$(eval _LIB_MK_TMP_MSUBST_VAL_ := $(strip $3)) \
$(eval $(foreach s,$1, \
        $(eval _LIB_MK_TMP_MSUBST_VAL_ := $(subst $s,$2,$(_LIB_MK_TMP_MSUBST_VAL_))))) \
$(strip $(_LIB_MK_TMP_MSUBST_VAL_)) \
$(eval _LIB_MK_TMP_MSUBST_VAL_ :=)
endef

# When updating replaced chars here, remember to update them in
# libdepsgen.pm in escape_path sub.
define escape-for-file
$(strip $(call multi-subst,- / . : +,_,$1))
endef

define path-to-file-with-suffix
$(strip $(call escape-for-file,$1).$2)
endef

define stamp-file
$(STAMPSDIR)/$(call path-to-file-with-suffix,$1,stamp)
endef

# Generates a stamp filename and assigns it to passed variable
# name. Generates a stamp's dependency on stamps directory. Adds stamp
# to CLEAN_FILES. Optional second parameter is for adding a suffix to
# stamp.
# Example: $(call setup-custom-stamp-file,FOO_STAMP,/some_suffix)
define setup-custom-stamp-file
$(eval $1 := $(call stamp-file,$2)) \
$(eval $($1): | $$(call to-dir,$($1))) \
$(eval CLEAN_FILES += $($1))
endef

# Generates a stamp filename and assigns it to passed variable
# name. Generates a stamp's dependency on stamps directory. Adds stamp
# to CLEAN_FILES. Optional second parameter is for adding a suffix to
# stamp.
# Example: $(call setup-stamp-file,FOO_STAMP,/some_suffix)
define setup-stamp-file
$(eval $(call setup-custom-stamp-file,$1,$(MK_PATH)$2))
endef

define dep-file
$(DEPSDIR)/$(call path-to-file-with-suffix,$1,dep.mk)
endef

define setup-custom-dep-file
$(eval $1 := $(call dep-file,$2)) \
$(eval $($1): | $$(call to-dir,$($1))) \
$(eval CLEAN_FILES += $($1))
endef

define setup-dep-file
$(eval $(call setup-custom-dep-file,$1,$(MK_PATH)$2))
endef

# 1 - test packages
# 2 - go list format item
# 3 - excluded directories
define go-find-directories-unstripped
$(eval _TST_ESCAPED_SRCDIR_ := $(MK_TOPLEVEL_ABS_SRCDIR)) \
$(eval _TST_ESCAPED_SRCDIR_ := $(subst .,\.,$(_TST_ESCAPED_SRCDIR_))) \
$(eval _TST_ESCAPED_SRCDIR_ := $(subst /,\/,$(_TST_ESCAPED_SRCDIR_))) \
$(eval _TST_SPACE_ := ) \
$(eval _TST_SPACE_ += ) \
$(eval _TST_FILES_ := $(shell $(GO_ENV) "$(GO)" list -f '{{.ImportPath}} {{.$2}}' $1 | \
        grep --invert-match '\[\]' | \
        sed -e 's/.*$(_TST_ESCAPED_SRCDIR_)\///' -e 's/[[:space:]]*\[.*\]$$//' \
        $(if $3,| grep --invert-match '^\($(subst $(_TST_SPACE_),\|,$3)\)'))) \
$(_TST_FILES_) \
$(eval _TST_ESCAPED_SRCDIR_ :=) \
$(eval _TST_SPACE_ :=) \
$(eval _TST_FILES_ :=)
endef

# Returns all not-excluded directories inside $REPO_PATH that have
# nonzero files matching given "go list -f {{.ITEM}}".
# 1 - where to look for files (./... to look for all files inside the project)
# 2 - a "go list -f {{.ITEM}}" item (GoFiles, TestGoFiles, etc)
# 3 - space-separated list of excluded directories
# Example: $(call go-find-directories,./...,TestGoFiles,tests)
define go-find-directories
$(strip $(call go-find-directories-unstripped,$1,$2,$3))
endef

# Returns 1 if both parameters are equal, otherwise returns empty
# string.
# Example: is_a_equal_to_b := $(if $(call equal,a,b),yes,no)
define equal
$(strip \
        $(eval _EQ_TMP_ := $(shell expr '$1' = '$2')) \
        $(filter $(_EQ_TMP_),1) \
        $(eval _EQ_TMP_ :=) \
)
endef

# Returns a string with all backslashes and double quotes escaped and
# wrapped in another double quotes. Useful for passing a string as a
# single parameter. In general the following should print the same:
# str := "aaa"
# $(info $(str))
# $(shell echo $(call escape-and-wrap,$(str)))
define escape-and-wrap
"$(subst ",\",$(subst \,\\,$1))"
endef
# "
# the double quotes in comment above remove highlighting confusion
