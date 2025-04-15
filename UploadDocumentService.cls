public class UploadDocumentService {
    
    //Get File Blob body from Image URL   
    public static blob getFile(String fileURL){
        HttpRequest imgreq = new HttpRequest();
        imgreq.setmethod('GET');
        imgreq.setEndpoint(fileURL);
        Http binding = new Http();
        HttpResponse imgres = binding.send(imgreq);
        System.debug('Response code for Image-->'+ imgres.getStatusCode());
        // converting response as a blob
        Blob imageblob = imgres.getBodyAsBlob();
        return imageblob ;
    }
    
    // this is use to get multipart/form-data from file body and file name to call post document api.
    
    public Static blob getMultiPartFormData(Blob file_body, String file_name){
        
        String boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW';
        String header = '--'+boundary+'\nContent-Disposition: form-data; name="file"; filename="'+file_name+'";\nContent-Type: application/octet-stream';
        // GW: Do not prepend footer with \r\n, you'll see why in a moment
        // String footer = '\r\n--'+boundary+'--'; 
        String footer = '--'+boundary;             
        String headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
        while(headerEncoded.endsWith('='))
        {
            header+=' ';
            headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
        }
        String bodyEncoded = EncodingUtil.base64Encode(file_body);
        // GW: Do not encode footer yet
        // String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
        
        Blob bodyBlob = null;
        String last4Bytes = bodyEncoded.substring(bodyEncoded.length()-4,bodyEncoded.length());
        
        // GW: replacement section to get rid of padding without corrupting data
        if(last4Bytes.endsWith('==')) {
            // The '==' sequence indicates that the last group contained only one 8 bit byte
            // 8 digit binary representation of CR is 00001101
            // 8 digit binary representation of LF is 00001010
            // Stitch them together and then from the right split them into 6 bit chunks
            // 0000110100001010 becomes 0000 110100 001010
            // Note the first 4 bits 0000 are identical to the padding used to encode the
            // second original 6 bit chunk, this is handy it means we can hard code the response in
            // The decimal values of 110100 001010 are 52 10
            // The base64 mapping values of 52 10 are 0 K
            // See http://en.wikipedia.org/wiki/Base64 for base64 mapping table
            // Therefore, we replace == with 0K
            // Note: if using \n\n instead of \r\n replace == with 'oK'
            last4Bytes = last4Bytes.substring(0,2) + '0K';
            bodyEncoded = bodyEncoded.substring(0,bodyEncoded.length()-4) + last4Bytes;
            // We have appended the \r\n to the Blob, so leave footer as it is.
            String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
            bodyBlob = EncodingUtil.base64Decode(headerEncoded+bodyEncoded+footerEncoded);
        }
        else if(last4Bytes.endsWith('=')) {
            // '=' indicates that encoded data already contained two out of 3x 8 bit bytes
            // We replace final 8 bit byte with a CR e.g. \r
            // 8 digit binary representation of CR is 00001101
            // Ignore the first 2 bits of 00 001101 they have already been used up as padding
            // for the existing data.
            // The Decimal value of 001101 is 13
            // The base64 value of 13 is N
            // Therefore, we replace = with N
            // Note: if using \n instead of \r replace = with 'K'
            last4Bytes = last4Bytes.substring(0,3) + 'N';
            bodyEncoded = bodyEncoded.substring(0,bodyEncoded.length()-4) + last4Bytes;
            // We have appended the CR e.g. \r, still need to prepend the line feed to the footer
            footer = '\n' + footer;
            String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
            bodyBlob = EncodingUtil.base64Decode(headerEncoded+bodyEncoded+footerEncoded);              
        } 
        else {
            // Prepend the CR LF to the footer
            footer = '\r\n' + footer;
            String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
            bodyBlob = EncodingUtil.base64Decode(headerEncoded+bodyEncoded+footerEncoded);  
        }
        return bodyBlob ;
    }
    
    
    // use for Parse the response JSON data
    public cls_documentUploadResponse documentUploadResponse;
    public class cls_documentUploadResponse {
        public String soId;	//100-0039-3120-19
        public cls_results results;
        public cls_document document;
    }
    public class cls_results {
        public cls_result result;
		public cls_error error;
    }
    public class cls_result {
        public String code;	//0000
        public String message;	//Document uploaded successfully
    }
    public class cls_error {
		public String code;	//0007
		public String message;	//Service order is not associated with the service provider.
	}
    public class cls_document {
        public String documentId;	//12345678
        public String uploadedTime;	//Feb 17, 2014 9:37:29 PM
    }
    public static UploadDocumentService parse(String json){
        return (UploadDocumentService) System.JSON.deserialize(json, UploadDocumentService.class);
    }
}