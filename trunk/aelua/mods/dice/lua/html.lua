

local sys=require("wetgenes.aelua.sys")

local wet_html=require("wetgenes.html")

local html=require("html")

local setmetatable=setmetatable

module("dice.html")

setmetatable(_M,{__index=html}) -- use a meta table to also return html base 


-----------------------------------------------------------------------------
--
-- overload footer
--
-----------------------------------------------------------------------------
footer=function(d)

	d=d or {}
	
	d.mod_name="dice"
	d.mod_link="http://boot-str.appspot.com/about/mod/dice"
	
	return html.footer(d)
end


-----------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------
dice_form=function(d)

	local cs=[[
<div style="float:left;width:75px" ><input type="radio" name="count" value="{v}" {checked} />{v}x</div>
]]
	local ds=[[
<div style="float:left;width:75px" ><input type="radio" name="side" value="{v}" {checked} />d{v}</div>
]]
	local ss=[[
<div style="float:left;width:100px" ><input type="radio" name="style" value="{v}" {checked} />{v}</div>
]]
	d.line1=""
	for i=1,#d.counts do local v=d.counts[i]
		local checked=""
		if v==d.count then checked="checked=\"checked\"" end
		d.line1=d.line1..wet_html.replace(cs,{v=v,checked=checked})
--		if (i%2)==0 then d.line1=d.line1.."<br/>" end
	end
		
	d.line2=""
	for i=1,#d.sides do local v=d.sides[i]
		local checked=""
		if v==d.side then checked="checked=\"checked\"" end
		d.line2=d.line2..wet_html.replace(ds,{v=v,checked=checked})
	end
	
	d.line3=""
	for i=1,#d.styles do local v=d.styles[i]
		local checked=""
		if v==d.style then checked="checked=\"checked\"" end
		d.line3=d.line3..wet_html.replace(ss,{v=v,checked=checked})
	end
	
	return wet_html.replace([[
	
<div class="#dice_title">
<h1>Choose your god!</h1>
</div>

<form class="jNice" name="dice_form" id="dice_form" action="" method="post">
	<div class="#dice_form">
		<div class="#dice_form_line1" style="float:left;width:150px;background-color:#f0f0ff" >
			{line1}
		</div>
		<div class="#dice_form_line2" style="float:left;width:75px;background-color:#f0ffff" >
			{line2}
		</div>
		<div class="#dice_form_line3" style="float:left;width:400px" >
			{line3}
		</div>
		<div class="#dice_form_submit" style="clear:both" >
			<input type="submit" name="submit" value="Roll dice!"/>
		</div>
	</div>
</form>


]],d)

end
			
			


