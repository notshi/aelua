
(function($){  
	
// update links into embeded things, useful for safe and simple embeding from users

$.fn.autoembedlink=function(opts)
{
	var defs = {  
		width:  600,
		height: 450
	};  
	opts = $.extend(defs, opts); 

	this.each(function(index) { // we are doing something different for each item so must iterate
	
	var link;
	var linktype="unknown";
	var tail;
	var dots;
	var aa;
	var vid;
	var box;
	var megaupload;
	var art;
	var slash;

	link=$(this).attr("href");

	if(!link) { return; }
	if(link.indexOf("#")>=0) { return; } // ignore links with fragments,
										 // so users can add a # at the end of a link to disable expansion

	dots=link.split(".");
	
	tail=dots[dots.length-1];
	tail=tail.toLowerCase();

	if( tail=="png" || tail=="gif" || tail=="jpg" || tail=="jpeg" )
	{
		linktype="image";
	}
	
	if(dots[1])
	{
		switch( dots[1].toLowerCase() )
		{
			case "wetgenes":
				switch( dots[0].toLowerCase() )
				{
					case "http://gallery":
						slash=link.split("/");
						if(slash[4]=="view")
						{
							art=slash[5];
							linktype="art";
						}
					break;
				}
			break;
			
			case "youtube":
			
				vid=link.split("v=")[1];
				
				if(vid)
				{
					vid=vid.substr(0,11); // there are 11 chars in a you tube id
					linktype="youtube";
				}
			
			break;
			
			case "veoh":
			
				vid=link.split("permalinkId=")[1];
				
				if(vid)
				{
					vid=vid.split("&")[0]; // the id before the &
					vid=vid.split("\"")[0]; // the id before the "
					vid=vid.split("'")[0]; // the id before the '
					linktype="veoh";
				}
			
			break;
			
			case "polldaddy":
				if(tail=="js")
				{
					poll=link.split(".js")[0];
					poll=poll.split("/p/")[1];
				}
				else
				{
					poll=link.split("/");
					poll=poll[poll.length-1] ? poll[poll.length-1] : poll[poll.length-2];
				}
				if(poll)
				{
					linktype="polldaddy";
				}
			break;
		}
	}
	
	switch(linktype)
	{
		case "polldaddy":
		
			$(this).before("<a name=\"pd_a_"+poll+"\" style=\"display: inline; padding: 0px; margin: 0px;\"></a><div class=\"PDS_Poll\" id=\"PDI_container"+poll+"\"></div><script type=\"text/javascript\" charset=\"utf-8\" src=\"http://static.polldaddy.com/p/"+poll+".js\"></script><br />");
			
		break;
		
		case "image":
		
			$(this).before("<a href=\""+link+"\"><img src=\""+link+"\" style=\"max-width:"+opts.width+"px;display:block;\" /></a>");
			
		break;
		
		case "art":
		
			$(this).before(
'<object width="'+opts.width+'" height="'+opts.height+'"><param name="movie" value="http://www.wetgenes.com/link/ItsaCoop.swf?art=*&artuid='+art+'"></param><param name="allowFullScreen" value="true"></param><embed src="http://www.wetgenes.com/link/ItsaCoop.swf?art=*&artuid='+art+'" type="application/x-shockwave-flash" allowfullscreen="true" width="'+opts.width+'" height="'+opts.height+'"></embed></object>'
			+"<br />"
			);
			
		break;
		
		case "youtube":
		
			$(this).before(
'<object width="'+opts.width+'" height="'+opts.height+'"><param name="movie" value="http://www.youtube.com/v/'+vid+'&hl=en&fs=1"></param><param name="allowFullScreen" value="true"></param><embed src="http://www.youtube.com/v/'+vid+'&hl=en&fs=1" type="application/x-shockwave-flash" allowfullscreen="true" width="'+opts.width+'" height="'+opts.height+'"></embed></object>'
			+"<br />"
			);
		
		break;
		
		case "veoh" :
		
			$(this).before(
'<embed src="http://www.veoh.com/static/swf/webplayer/WebPlayer.swf?version=AFrontend.5.4.3.1006&permalinkId='+vid+'&player=videodetailsembedded&videoAutoPlay=0&id=anonymous" type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" width="'+opts.width+'" height="'+opts.height+'" ></embed>'
			+"<br />"
			);
		
		break;
		
	}
	
	});

	return this;
}

})(jQuery);
