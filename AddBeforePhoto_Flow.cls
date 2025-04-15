global class AddBeforePhoto_Flow {
    
    @InvocableMethod(label='Add Before Photo ' description='This method is used to make a callout to external platform')
    global Static Void addBeforePhoto(List<String> cdIds) {
        System.debug('cdIds : '+cdIds);
        System.debug('cdIds.size() : '+cdIds.size());
        String myInput = cdIds[0].substringBetween('[',']');
        List<String> cdIdSplit = myInput.split(',');
        String saId = cdIdSplit[0];
        ServiceAppointment saObj = [Select Id,FSSK__FSK_Work_Order__c,FSSK__FSK_Work_Order__r.Tracking_Number__c from ServiceAppointment where id=: saId];
        System.debug('cdIdSplit.size() : '+cdIdSplit.size());
        System.debug('saId : '+saId);
        List<Before_Photo__c> beforePhotoRecordList = new List<Before_Photo__c>();
        for(Integer i=1;i<cdIdSplit.size();i++){
            String comInput = saObj.FSSK__FSK_Work_Order__r.Tracking_Number__c+','+cdIdSplit[i];
            Before_Photo__c BP_Record = uploadCallOutBeforePhoto(saObj.Id,comInput);
            if(BP_Record.ServiceLive_Document_Id__c !=null)
                beforePhotoRecordList.add(BP_Record);
        }
        if(beforePhotoRecordList !=null && !beforePhotoRecordList.isEmpty()){
            insert beforePhotoRecordList ;
        }
    }
    
    global Static Before_Photo__c uploadCallOutBeforePhoto(Id serviceAppId,String comInput){
        String serviceorderId = comInput.substringBefore(',');
        String cdId = comInput.substringAfter(',');
        System.debug('serviceorderId --- >' +serviceorderId);
        System.debug('cdId --- >' +cdId);
        ContentVersion cvData =  [SELECT Id,ContentDocumentId,FileExtension,Title,VersionNumber,IsLatest,VersionData FROM ContentVersion WHERE ContentDocumentId =: cdId];
        System.debug('cvData --- >' +cvData);
        
        //Create Before Photo Record---=>
        Before_Photo__c BP_Record = new Before_Photo__c();
        BP_Record.Photo_Label__c = cvData.Title+'.'+cvData.FileExtension ;
        BP_Record.Service_Appointment__c = serviceAppId;
        
        String resourceId = '10254';
        String myToken = AccessTokenGenerator.oauthLogin();
        if(myToken!=null){       
            List<ServiceLiveAuthTokens__c> refreshTokenList = [select id,Authorization__c,EndpointUrl__c,Content_Type__c from ServiceLiveAuthTokens__c];
            if(!refreshTokenList.isEmpty()){
                blob bodyBlob = UploadDocumentService.getMultiPartFormData(cvData.VersionData, cvData.Title+'.'+cvData.FileExtension);
                String boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW';
                String EndpointUrl = refreshTokenList[0].EndpointUrl__c+'/provider/v1.0/resource/'+resourceId+'/serviceorder/'+serviceorderId+'/uploadDocument';
                String AuthorizationforAccess = 'Bearer '+ myToken;
                
                System.debug('bodyBlob :'+bodyBlob);
                HttpRequest req1 = new HttpRequest();
                req1.setEndpoint(EndpointUrl); 
                req1.setTimeout(120000);
                req1.setMethod('POST');
                req1.setHeader('Connection', 'keep-alive');
                req1.setHeader('Authorization', AuthorizationforAccess);  
                req1.setHeader('Content-Type','multipart/form-data; boundary='+boundary);
                req1.setBodyAsBlob(bodyBlob);
                //   req1.setBody(body);
                Http http1 = new Http();
                try {
                    
                    HTTPResponse response = http1.send(req1);   
                    system.debug('status1---'+response.getStatusCode());
                    system.debug('message1---'+response.getStatus());
                    if (response.getStatusCode() == 200) {
                        String sBody = response.getBody();
                        System.debug('Body-->'+sBody);
                        UploadDocumentService resBody  = (UploadDocumentService)JSON.deserialize(sBody,UploadDocumentService.class);
                        System.debug('resBody  :'+resBody);
                        if(resBody!=null && resBody.documentUploadResponse.document !=null){
                            System.debug('resBody Success  :'+resBody);
                            //Add uploaded document Id in Before Photo Record
                            //https://servus--appscrip.my.salesforce.com
                            String baseUrl = String.valueOf(System.Url.getOrgDomainUrl()).substringBetween('=',']');
                            BP_Record.Photo_URL__c = baseUrl+'/lightning/r/ContentDocument/'+cvData.ContentDocumentId+'/view';
                            BP_Record.ServiceLive_Document_Id__c = resBody.documentUploadResponse.document.documentId;
                        }
                        else if(resBody!=null && resBody.documentUploadResponse.results.error !=null){
                            String errorMsg = resBody.documentUploadResponse.results.error.message;
                            System.debug('Error : '+errorMsg);
                        }
                    }
                    else {
                        System.debug(response.getBody());
                    }
                }
                catch (Exception e) {
                    System.debug('Body-->'+e.getMessage());
                }
            }
        }
        return BP_Record ;
    }
    
}