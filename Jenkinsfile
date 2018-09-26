properties([[$class: 'BuildDiscarderProperty',
            strategy: [$class: 'LogRotator', artifactDaysToKeepStr: '', artifactNumToKeepStr: '1',
daysToKeepStr: '60', numToKeepStr: '60']],
            [$class: 'RebuildSettings', autoRebuild: false, rebuildDisabled: false],
            [$class: 'ParametersDefinitionProperty', parameterDefinitions: [
            [$class: 'StringParameterDefinition', defaultValue: '6.0-SNAPSHOT', description:
'Product version to build', name: 'NUXEO_VERSION'],
            [$class: 'StringParameterDefinition', defaultValue: '', description: 'Optional - Use the
specified URL (eg a link to staging) as the source for the distribution             instead of
maven', name: 'DISTRIBUTION_URL'],
            [$class: 'BooleanParameterDefinition', defaultValue: true, description: 'Build debian
package', name: 'BUILD_DEB'],
            [$class: 'BooleanParameterDefinition', defaultValue: true, description: 'Publish debian
package', name: 'PUBLISH_DEB'],
            [$class: 'StringParameterDefinition', defaultValue:
'/var/www/community.nuxeo.com/static/staging/', description: 'Staging publishing destination path
(for scp)', name: 'STAGING_PATH'],
            [$class: 'StringParameterDefinition', defaultValue: 'nuxeo@lethe.nuxeo.com',
description: 'Publishing destination host (for scp)', name: 'DEPLOY_HOST']]],
            pipelineTriggers([])])

node('OLDJOYEUX') {
    timestamps {
        timeout(time: 240, unit: 'MINUTES') {
            sh '''
                #!/bin/bash -ex

                if [ -n "$DISTRIBUTION_URL" ]; then
                    DISTRIBUTION="-Ddistribution.archive=$DISTRIBUTION_URL"
                else
                DISTRIBUTION=""
                fi

                if [ "$BUILD_DEB" = "true" ]; then
                    echo "*** "$(date +"%H:%M:%S")" Cloning/updating nuxeo-packaging-debian"
                    if [ ! -d nuxeo-packaging-debian ]; then
                        git clone git@github.com:nuxeo/nuxeo-packaging-debian.git
                    fi

                    OLDPATH="$PWD"
                    cd nuxeo-packaging-debian
                    git pull

                    if [ "$PUBLISH_DEB" = "true" ]; then
                        echo "*** "$(date +"%H:%M:%S")" Building and publishing .deb package"
                        mvn clean deploy -Ddistribution.version=$NUXEO_VERSION $DISTRIBUTION
                        echo "*** "$(date +"%H:%M:%S")" Publishing .deb package to staging"
                        PKG=$(find . -name '*.deb' -print | head -n 1)
                        FILENAME=$(basename $PKG)
                        scp $PKG ${DEPLOY_HOST}:$STAGING_PATH
                        echo "*** "$(date +"%H:%M:%S")" Generating .deb package signatures on
staging"
                        ssh ${DEPLOY_HOST} "cd $STAGING_PATH && md5sum $FILENAME > ${FILENAME}.md5
&& sha256sum $FILENAME > ${FILENAME}.sha256"
                    else
                        echo "*** "$(date +"%H:%M:%S")" Building .deb package"
                        mvn clean package -Ddistribution.version=$NUXEO_VERSION $DISTRIBUTION
                    fi
                    cd $OLDPATH
                fi
                '''
        }
    }
}
