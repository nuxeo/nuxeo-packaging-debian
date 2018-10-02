/*
 * (C) Copyright ${year} Nuxeo (http://nuxeo.com/) and others.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Contributors:
 *     mguillaume
 *     atimic
 */

properties([[$class: 'BuildDiscarderProperty',
            strategy: [$class: 'LogRotator', artifactDaysToKeepStr: '', artifactNumToKeepStr: '1', daysToKeepStr: '60', numToKeepStr: '60']],
            [$class: 'RebuildSettings', autoRebuild: false, rebuildDisabled: false],
            [$class: 'ParametersDefinitionProperty', parameterDefinitions: [
            [$class: 'StringParameterDefinition', defaultValue: '6.0-SNAPSHOT', description: 'Product version to build', name: 'NUXEO_VERSION'],
            [$class: 'StringParameterDefinition', defaultValue: '', description: 'Optional - Alternate URL to download the distribution from instead of the default Maven artifact download. For instance: http://community.nuxeo.com/static/snapshots/nuxeo-server-tomcat-10.3-SNAPSHOT.zip', name: 'DISTRIBUTION_URL'],
            [$class: 'BooleanParameterDefinition', defaultValue: true, description: 'Publish debian package', name: 'PUBLISH_DEB'],
            [$class: 'StringParameterDefinition', defaultValue: '/var/www/community.nuxeo.com/static/staging/', description: 'Staging publishing destination path (for scp)', name: 'STAGING_PATH'],
            [$class: 'StringParameterDefinition', defaultValue: 'nuxeo@lethe.nuxeo.com', description: 'Publishing destination host (for scp)', name: 'DEPLOY_HOST']]],
            ])

node('OLDJOYEUX') {
    timestamps {
        timeout(time: 240, unit: 'MINUTES') {

           checkout poll: false, scm: [$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [],
            userRemoteConfigs: [[url: 'git@github.com:nuxeo/nuxeo-packaging-debian.git']]]
            sh '''
                #!/bin/bash -ex

                MAVEN_OPTS="-Xmx512m -Xmx2048m"

                if [ -n "$DISTRIBUTION_URL" ]; then
                    DISTRIBUTION="-Ddistribution.archive=$DISTRIBUTION_URL"
                else
                DISTRIBUTION=""
                fi

                cd nuxeo-packaging-debian

                if [ "$PUBLISH_DEB" = "true" ]; then
                    echo "*** "$(date +"%H:%M:%S")" Building and publishing .deb package"
                    mvn clean deploy -Ddistribution.version=$NUXEO_VERSION $DISTRIBUTION
                    echo "*** "$(date +"%H:%M:%S")" Publishing .deb package to staging"
                    PKG=$(find . -name '*.deb' -print | head -n 1)
                    FILENAME=$(basename $PKG)
                    scp $PKG ${DEPLOY_HOST}:$STAGING_PATH
                    echo "*** "$(date +"%H:%M:%S")" Generating .deb package signatures on staging"
                    ssh ${DEPLOY_HOST} "cd $STAGING_PATH && md5sum $FILENAME > ${FILENAME}.md5 && sha256sum $FILENAME > ${FILENAME}.sha256"
                else
                    echo "*** "$(date +"%H:%M:%S")" Building .deb package"
                    mvn clean package -Ddistribution.version=$NUXEO_VERSION $DISTRIBUTION
                fi
                '''
        }
    }
}
