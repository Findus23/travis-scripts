#!/bin/bash
# NOTE: this script is executed with Piwik master checked out. After it is run, Piwik master may not be checked out.

SCRIPT_DIR=`dirname $0`

if [ "$TEST_AGAINST_PIWIK_BRANCH" == "" ]; then
    if [ "$TEST_AGAINST_CORE" == "latest_stable" ]; then # test against the latest stable release of piwik core (including betas & release candidates)
        # keeping latest_stable enabled until all plugins successfully migrated
        export TEST_AGAINST_PIWIK_BRANCH=$(git describe --tags `git rev-list --tags --max-count=1`)
        export TEST_AGAINST_PIWIK_BRANCH=`echo $TEST_AGAINST_PIWIK_BRANCH | tr -d ' ' | tr -d '\n'`

        #echo "Testing against 'latest_stable' is no longer supported, please test against 'minimum_required_piwik'."
        #exit 1
    elif [[ "$TEST_AGAINST_CORE" == "minimum_required_piwik" && "$PLUGIN_NAME" != "" ]]; then # test against the minimum required Piwik in the plugin.json file
        export TEST_AGAINST_PIWIK_BRANCH=$(php "$SCRIPT_DIR/get_required_piwik_version.php" $PLUGIN_NAME)

        if ! git rev-parse "$TEST_AGAINST_PIWIK_BRANCH" >/dev/null 2>&1
        then
            echo "Could not find tag '$TEST_AGAINST_PIWIK_BRANCH' specified in plugin.json, testing against master."

            export TEST_AGAINST_PIWIK_BRANCH=master
        fi
    else
        export TEST_AGAINST_PIWIK_BRANCH=master
    fi
fi

echo "Testing against '$TEST_AGAINST_PIWIK_BRANCH'"
git checkout "$TEST_AGAINST_PIWIK_BRANCH"

echo "Initializing submodules"
git submodule init -q
git submodule update -q || true

echo "Making sure travis-scripts submodule is being used"
if [ ! -d ./tests/travis/.git ]; then
    echo "Older Piwik w/o travis-scripts submodule, checking out."

    rm -rf ./tests/travis

    git clone https://github.com/piwik/travis-scripts.git ./tests/travis
fi

cd tests/travis

if git rev-parse --verify "$TEST_AGAINST_PIWIK_BRANCH" ; then
    echo "Found travis-scripts branch or tag corresponding to TEST_AGAINST_PIWIK_BRANCH environment variable, checking out '$TEST_AGAINST_PIWIK_BRANCH' for tests."

    git checkout "$TEST_AGAINST_PIWIK_BRANCH"
fi