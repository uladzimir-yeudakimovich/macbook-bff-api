#!/bin/bash

TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
ARCHIVE_NAME=deploy-$TIMESTAMP.zip
BUILD_FOLDER=dist
EB_PATH=./.elasticbeanstalk
EB_CONFIG=$EB_PATH/config.yml
MODULES_DIR=$EB_PATH/.cached-modules
UPLOAD_PATH=$EB_PATH/upload

echo '### Creating build...' \
&& npm run build >/dev/null \
&& rm -rf $EB_PATH/upload/dist >/dev/null \
&& mkdir -p $_ >/dev/null \
&& cp -r ./$BUILD_FOLDER/* $_ >/dev/null \
&& echo '### Complete 1/5' \
&& echo '### Installing modules...' \
&& if [[ "$npm" == "cache" && -d "$MODULES_DIR" ]];
  then
    echo '### [CACHED MODULES]'
  else
    mkdir -p $MODULES_DIR >/dev/null \
    && cp -r ./package*.json $_ >/dev/null \
    && cd $MODULES_DIR \
    && npm ci --production &>/dev/null \
    && rm package-lock.json &>/dev/null \
    && cd ../..
fi \
&& cp -r $MODULES_DIR/* $UPLOAD_PATH \
&& cp -rf ./.ebextensions $UPLOAD_PATH &>/dev/null | true \
&& cp -rf ./Procfile $UPLOAD_PATH &>/dev/null | true \
&& echo '### Complete 2/5' \
&& echo '### Archiving...' \
&& cd $UPLOAD_PATH \
&& zip -r ../$ARCHIVE_NAME ./ &>/dev/null \
&& cd ../.. \
&& echo '### Complete 3/5' \
&& echo '### Deploying...' \
&& sed '/deploy*/d;/test\.com/d' -i $EB_CONFIG \
&& sed '/artifact*/d;/test\.com/d' -i $EB_CONFIG \
&& printf '%s\n  %s\n' 'deploy:' 'artifact: '$EB_PATH/$ARCHIVE_NAME >> $EB_CONFIG \
&& eb deploy --staged \
&& echo 'Complete 4/5'

# Remove created files
echo '### Remove created files...'
rm -rf $EB_PATH/$ARCHIVE_NAME &>/dev/null
rm -rf $UPLOAD_PATH &>/dev/null
sed '/deploy*/d;/test\.com/d' -i $EB_CONFIG
sed '/artifact*/d;/test\.com/d' -i $EB_CONFIG
echo '### All completed 5/5'
