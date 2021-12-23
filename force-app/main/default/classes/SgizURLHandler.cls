// Author 	: Henry Caballero - hdcaballero@gmail.com
// Date		: 4/18/2017
public class SgizURLHandler 
{
    public static void updateURL(list<Fulfillment__c> fulfillments )
    {
        for (Fulfillment__c f : fulfillments)
        {
            if (f.Product_Name__c!=null)
          	  f.Generated_Sgiz_URL__c = generateURL(f.Product_Name__c)  ;
        }
        
    }
    
    public static string generateURL(string text)
    {
        
        string URL = 'http://fivestar.{product}.sgizmo.com/s3/'; 
        
        if (lookForKeyword( 'Half Page' , text ) )
        	URL = URL.replace('{product}', '4b44e8a61055');
        else if (lookForKeyword( 'Desk' , text ) )
        	URL = URL.replace('{product}', '75adff733621');
        else if (lookForKeyword( 'Announcement' , text ) )
        	URL = URL.replace('{product}', '9de0380293c0');
        else if (lookForKeyword( 'Postcard' , text ) )
        	URL = URL.replace('{product}', 'fe4f8a533c8d');
        else if (lookForKeyword( 'Ninth Page' , text ) )
        	URL = URL.replace('{product}', '667117802497');
        else if (lookForKeyword( 'Brochure' , text ) )
        	URL = URL.replace('{product}', '61447657a3c9');
        else if (lookForKeyword( 'Full Page' , text ) )
        	URL = URL.replace('{product}', '67e7a908bbf4');
        else if (lookForKeyword( 'Eighteenth Page' , text ) )
        	URL = URL.replace('{product}', '29b275869e66');
        else if (lookForKeyword( 'Single Wall' , text ) )
        	URL = URL.replace('{product}', '1167109c1aab');
       	else if (lookForKeyword( 'Double Wall' , text ) )
        	URL = URL.replace('{product}', '77dc18ce605c');
        else if (lookForKeyword( 'Quarter Page' , text ) )
        	URL = URL.replace('{product}', 'f4bc1882f58c');
        else if (lookForKeyword( 'Two Page' , text ) )
        	URL = URL.replace('{product}', '9c874226ebe9');
        else if (lookForKeyword( 'Rider Sign' , text ) )
        	URL = URL.replace('{product}', 'edfc1dadd2bd');
        else if (lookForKeyword( 'Magazine Listing' , text ) )
        	URL = URL.replace('{product}', 'b7c9e2fabf76');
        else if (lookForKeyword( 'WSJ Listing' , text ) )
        	URL = URL.replace('{product}', 'd5d8f3470d90');
        else if (lookForKeyword( 'Press release' , text ) )
        	URL = URL.replace('{product}', 'ca83189991f4');
        else if (lookForKeyword( 'WSJ single profile' , text ) )
        	URL = URL.replace('{product}', '54908b9be74b');
        else if (lookForKeyword( 'WSJ double profile' , text ) )
        	URL = URL.replace('{product}', '516e550694c8');
        else if (lookForKeyword( 'Digital ad campaign' , text ) )
        	URL = URL.replace('{product}', '8b0db1019b23');
        else if (lookForKeyword( 'Forbes profile' , text ) )
        	URL = URL.replace('{product}', '1fd4a1f32744');
 		else URL = null;
        
        return URL;
    }
    
    public static boolean lookForKeyword(string key, string input)
    {
        input = input.toLowerCase();
		key = key.toLowerCase();
        
        
        list<string> words = key.split(' ');   
        string regExp= '';
        for (string w : words)
        {
            regExp=regExp + '(?=.*\\b' + w + '\\b)';
        }
        regExp+='.*';
        
        return  pattern.matches(regExp, input);
    }
    
}