#!/usr/bin/env bash

#############
# Constants #
#############

# 1-10 is reservated for custom return codes
ERROR_ILLEGAL_NUMBER_OF_ARGS=11
ERROR_CANT_PARSE_ARGUMENTS=12
ERROR_FILE_DOES_NOT_EXIST=13
ERROR_CANT_CHANGE_DIRECTORY=14

####################
# Helper functions #
####################

echoerr() { echo "ERROR: $*" 1>&2; }
