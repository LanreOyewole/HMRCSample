#!/bin/bash

# This block is entered only if the $apiUsername variable has been set/passed from the apiBuild.xml Ant task
if [ -n "$apiUsername" ]
then
	# Login to the APIM Admin Service (AuthenticationAdmin) and get a SESSION token 
	echo -e "\n\nAdminService Login _________________________________________##########################________________________________________________\n\n"
	curl -v -k -X POST -c cookies https://${target_api_hostname}:${target_api_port}/services/AuthenticationAdmin.AuthenticationAdminHttpsSoap11Endpoint --header "SOAPAction: urn:login" --header "Content-Type: text/xml;charset=UTF-8" -d "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:aut=\"http://authentication.services.core.carbon.wso2.org\"><soapenv:Header/><soapenv:Body><aut:login><aut:username>${target_api_username}</aut:username><aut:password>${target_api_username}</aut:password><aut:remoteAddress>${target_api_hostname}</aut:remoteAddress></aut:login></soapenv:Body></soapenv:Envelope>"
	echo -e "\n\n";

	# Delete the API user in the Admin Service, if it already exists
	echo -e "\n\nAdminService Delete User____________________________________##########################________________________________________________\n\n"
	curl -v -k -X POST -b cookies https://${target_api_hostname}:${target_api_port}/services/UserAdmin.UserAdminHttpsSoap11Endpoint --header "SOAPAction: urn:deleteUser" --header "Content-Type: text/xml;charset=UTF-8" -d "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:xsd=\"http://org.apache.axis2/xsd\"><soapenv:Header/><soapenv:Body><xsd:deleteUser><xsd:userName>${apiUsername}</xsd:userName></xsd:deleteUser></soapenv:Body></soapenv:Envelope>"
	echo -e "\n\n";

	# Create the API user in the Admin Service (UserAdmin)
	echo -e "\n\nAdminService Create User____________________________________##########################________________________________________________\n\n"
	curl -v -k -X POST -b cookies https://${target_api_hostname}:${target_api_port}/services/UserAdmin.UserAdminHttpsSoap11Endpoint --header "SOAPAction: urn:addUser" --header "Content-Type: text/xml;charset=UTF-8" -d "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:xsd=\"http://org.apache.axis2/xsd\" xmlns:xsd1=\"http://common.mgt.user.carbon.wso2.org/xsd\"><soapenv:Header/><soapenv:Body><xsd:addUser><xsd:userName>${apiUsername}</xsd:userName><xsd:password>${apiPassword}</xsd:password><xsd:roles>${apiRole}</xsd:roles></xsd:addUser></soapenv:Body></soapenv:Envelope>"
	echo -e "\n\n";
fi

# Login to the API Manager (Store)
echo -e "\n\nStore Login ________________________________________________##########################________________________________________________\n\n"
curl -v -k -X POST -c cookies https://${target_api_hostname}:${target_api_port}/store/site/blocks/user/login/ajax/login.jag -d "action=login&username=${target_api_username}&password=${target_api_password}" 2>&1
echo -e "\n\n";
#sleep 3;

# Create the API user - DEPRECATED; now made redundant by call to Admin Service (UserAdmin)
#echo -e "\n\nCarbon CreateUser __________________________________________##########################________________________________________________\n\n"
#curl -v -k -b cookies https://${target_api_hostname}:${target_api_port}/store/site/blocks/user/sign-up/ajax/user-add.jag --data "action=addUser&username=${apiUsername}&password=${apiPassword}&allFieldsValues=${apiUsername}|User|Exeter University|St Luke&#39;s Campus,Exeter,England|UK|info@exeter.ac.uk|000000|000000|AutoAPIUser" 2>&1
#echo -e "\n\n";
##sleep 10;

# Delete Subscription to the DefaultApplication for the API
echo -e "\n\nUnsubscribe API_____________________________________________##########################________________________________________________\n\n"
curl -v -k -X POST -b cookies https://${target_api_hostname}:${target_api_port}/store/site/blocks/subscription/subscription-remove/ajax/subscription-remove.jag -d "action=removeSubscription&name=${apiName}&version=${apiVersion}&provider=admin&applicationName=DefaultApplication" 2>&1
echo -e "\n\n";
#sleep 3;

# Login to the API Manager (Publisher)
echo -e "\n\nPublisher Login ____________________________________________##########################________________________________________________\n\n"
curl -v -k -X POST -c cookies https://${target_api_hostname}:${target_api_port}/publisher/site/blocks/user/login/ajax/login.jag -d "action=login&username=${target_api_username}&password=${target_api_password}" 2>&1
#sleep 3;

# Delete the API, if it exists
echo -e "\n\nDelete API _________________________________________________##########################________________________________________________\n\n"
curl -v -k -X POST -b cookies https://${target_api_hostname}:${target_api_port}/publisher/site/blocks/item-add/ajax/remove.jag -d "action=removeAPI&name=${apiName}&context=/${apiName}&version=${apiVersion}&provider=admin" 2>&1
#sleep 3;

# Create the API
echo -e "\n\nCreate API _________________________________________________##########################________________________________________________\n\n"
JSON_FILE=$(sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g' $fileName) ## Replace new lines with space characters
JSON_FILE=$(echo ${JSON_FILE} | sed 's/&/%26/g') # URL-encode all ampersand characters in the JSON payload
API_CONTEXT=$(echo ${eiBasePath} | sed "s/\/\([a-z0-9]\+\).[a-z0-9]$//ig") ## Remove everything from the last forward-slash to the end of the string
if [ -n "${securityType}" ]
then
    ENDPOINT_TYPE_DEF="secured&endpointAuthType=${securityType}&epUsername=${securityUsername}&epPassword=${securityPassword}"
else
    ENDPOINT_TYPE_DEF="nonsecured"
fi
curl -v -k -X POST -b cookies -d "action=addAPI&name=${apiName}&context=${API_CONTEXT}&version=${apiVersion}&visibility=public&thumbUrl=&description=&tags=&endpointType=${ENDPOINT_TYPE_DEF}&tiersCollection=Unlimited&default_version_checked=default_version&http_checked=http&https_checked=https" -d 'endpoint_config={"sandbox_endpoints":{"url":"http://'${eiHostPort}/${endpoint}'","config":null},"production_endpoints":{"url":"http://'${eiHostPort}/${endpoint}'","config":null},"endpoint_type":"http"}' -d "swagger=${JSON_FILE}" https://${target_api_hostname}:${target_api_port}/publisher/site/blocks/item-add/ajax/add.jag
echo -e "\n\n";
#sleep 10;

# Set the API state to PUBLISHED
echo -e "\n\nPublish API ________________________________________________##########################________________________________________________\n\n"
curl -v -k -X POST -b cookies "https://${target_api_hostname}:${target_api_port}/publisher/site/blocks/life-cycles/ajax/life-cycles.jag" -d "action=updateStatus&name=${apiName}&version=${apiVersion}&provider=admin&status=PUBLISHED&publishToGateway=true&requireResubscription=false" 2>&1
echo -e "\n\n";
#sleep 10;

# Login to the API Manager (Store)
echo -e "\n\nStore Login ________________________________________________##########################________________________________________________\n\n"
curl -v -k -X POST -c cookies https://${target_api_hostname}:${target_api_port}/store/site/blocks/user/login/ajax/login.jag -d "action=login&username=${target_api_username}&password=${target_api_password}" 2>&1
echo -e "\n\n";
#sleep 3;

# Create a Subscription to the Application for the API
echo -e "\n\nSubscribe API ______________________________________________##########################________________________________________________\n\n"
curl -v -k -X POST -b cookies https://${target_api_hostname}:${target_api_port}/store/site/blocks/subscription/subscription-add/ajax/subscription-add.jag -d "action=addAPISubscription&name=${apiName}&version=${apiVersion}&provider=admin&tier=Unlimited&applicationName=DefaultApplication" 2>&1
echo -e "\n\n";
#sleep 3;

# Generate Application Keys for the test Application
echo -e "\n\nGenKey API _________________________________________________##########################________________________________________________\n\n"
APP_RSP=$(curl -v -k -X POST -b cookies https://${target_api_hostname}:${target_api_port}/store/site/blocks/subscription/subscription-add/ajax/subscription-add.jag -d "action=generateApplicationKey&application=DefaultApplication&keytype=PRODUCTION&callbackUrl=&authorizedDomains=ALL&validityTime=-1" --header "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8") 2>&1
echo -e "\n\nAPIM Response: ${APP_RSP}\n\n";
#sleep 10;

rm cookies || true


