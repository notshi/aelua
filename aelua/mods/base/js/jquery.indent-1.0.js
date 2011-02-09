(function($) {
	var textarea;
	var lb = '\n';
	
	$.fn.indent = function() 
	{	
		textarea = this;

		if(!$.browser.opera) textarea.keydown(key_handler);
		else textarea.keypress(key_handler); // opera fix
		
		if($.browser.msie || $.browser.opera) lb = '\r\n';
				
		return this;
	};
	
	function key_handler(e)
	{
		
		if(e.keyCode == 13) {
			var start = selection_range().start;
			var line = textarea[0].value.substring(0,start).lastIndexOf('\n');
			line = (line == -1 ? 0 : line + 1);
			
			var matches = textarea[0].value.substring(line,start).match(/^\t+/g);
			if(matches != null)
			{
				e.preventDefault();
				var scroll_fix = fix_scroll_pre();
				var tabs = lb;
				for(var i = 0;i < matches[0].length;i++) tabs += '\t';
				textarea[0].value = textarea[0].value.substring(0,start) + tabs + textarea[0].value.substring(start);
				set_focus(start + tabs.length,start + tabs.length);
				fix_scroll(scroll_fix);
			}
		}
		else if(e.keyCode == 9)
		{			
			e.preventDefault();
			
			var scroll_fix = fix_scroll_pre();
			
			var range = selection_range();
			
			if(range.start != range.end && textarea[0].value.substr(range.start, 1) == '\n') range.start++;
			
			var matches = textarea[0].value.substring(range.start,range.end).match(/\n/g); // check if multiline
			
			if(matches != null)
			{
				var index = textarea[0].value.substring(0,range.start).lastIndexOf(lb);
				var start_tab = (index != -1 ? index : 0);
				
				if(!e.shiftKey)
				{
					var tab = textarea[0].value.substring(start_tab,range.end).replace(/\n/g,'\n\t');
					
					textarea[0].value = (index == -1 ? '\t' : '') + textarea[0].value.substring(0,start_tab) + tab + textarea[0].value.substring(range.end);

					set_focus(range.start + 1,range.end + matches.length + 1);
				}
				else
				{
					var i = (textarea[0].value.substr((index != -1 ? index + lb.length : 0),1) == '\t' ? 1 : 0);
					
					var removed = textarea[0].value.substring(start_tab,range.end).match(/\n\t/g,'\n');
					
					if(index == -1 && textarea[0].value.substr(0,1) == '\t') 
					{
						textarea[0].value = textarea[0].value.substr(1);
						removed.push(0); // null problem in IE 7
					}
					
					var tab = textarea[0].value.substring(start_tab,range.end).replace(/\n\t/g,'\n');
					
					textarea[0].value = textarea[0].value.substring(0,start_tab) + tab + textarea[0].value.substring(range.end);
					
					set_focus(range.start - i,range.end - (removed != null ? removed.length : 0));
				}
			}
			else
			{	
				if(!e.shiftKey)
				{
					textarea[0].value = textarea[0].value.substring(0,range.start) + '\t'  + textarea[0].value.substring(range.start);
					set_focus(range.start + 1,range.start + 1);
				}
				else
				{
					var i_o = textarea[0].value.substring(0,range.start).lastIndexOf('\n'); // index open (start line) -1 = first line
					var i_s = (i_o == -1 ? 0 : i_o); // index start line

					var i_e = textarea[0].value.substring(i_s + 1).indexOf('\n'); // index end of line -1 = last line
					if(i_e == -1) i_e = textarea[0].value.length;
					else i_e += i_s + 1;

					if(i_o == -1)
					{
						var match = textarea[0].value.substring(i_s,i_e).match(/^\t/);
						var tab = textarea[0].value.substring(i_s,i_e).replace(/^\t/,'');
					}
					else
					{
						var match = textarea[0].value.substring(i_s,i_e).match(/\n\t/);
						var tab = textarea[0].value.substring(i_s,i_e).replace(/\n\t/,'\n');
					}
					
					textarea[0].value = textarea[0].value.substring(0,i_s) + tab + textarea[0].value.substring(i_e);

					if(match != null) set_focus(range.start - (range.start - 1 > i_o ? 1 : 0),range.end - ((range.start - 1 > i_o || range.start != range.end) ? 1 : 0));
				}
			}
			
			fix_scroll(scroll_fix);
		}
	}
	
	function fix_scroll_pre()
	{
		return {
			scrollTop:textarea.scrollTop(),
			scrollHeight:textarea[0].scrollHeight
		}
	}
	
	function fix_scroll(obj)
	{
		textarea.scrollTop(obj.scrollTop + textarea[0].scrollHeight - obj.scrollHeight);
	}
		
	function set_focus(start,end)
	{
		if(!$.browser.msie)
		{
			textarea[0].setSelectionRange(start,end);
			textarea.focus();
		}
		else
		{
			var m_s = textarea[0].value.substring(0,start).match(/\r/g);
			m_s = (m_s != null ? m_s.length : 0);
			var m_e = textarea[0].value.substring(start,end).match(/\r/g);
			m_e = (m_e != null ? m_e.length : 0);
			
			var range = textarea[0].createTextRange();
			range.collapse(true);
			range.moveStart('character', start - m_s); 
			range.moveEnd('character', end - start - m_e);
			range.select();
		}
	};
	
	function selection_range()
	{
		if(!$.browser.msie)
		{
			return {start: textarea[0].selectionStart,end: textarea[0].selectionEnd}
		}
		else
		{			
			var selection_range = document.selection.createRange().duplicate();
			
			var before_range = document.body.createTextRange();
			before_range.moveToElementText(textarea[0]);                    // Selects all the text
			before_range.setEndPoint("EndToStart", selection_range);     // Moves the end where we need it

			var after_range = document.body.createTextRange();
			after_range.moveToElementText(textarea[0]);                     // Selects all the text
			after_range.setEndPoint("StartToEnd", selection_range);      // Moves the start where we need it

			var before_finished = false, selection_finished = false, after_finished = false;
			var before_text, untrimmed_before_text, selection_text, untrimmed_selection_text, after_text, untrimmed_after_text;

			before_text = untrimmed_before_text = before_range.text;
			selection_text = untrimmed_selection_text = selection_range.text;
			after_text = untrimmed_after_text = after_range.text;

			do {
			  if (!before_finished) {
			      if (before_range.compareEndPoints("StartToEnd", before_range) == 0) {
			          before_finished = true;
			      } else {
			          before_range.moveEnd("character", -1)
			          if (before_range.text == before_text) {
			              untrimmed_before_text += "\r\n";
			          } else {
			              before_finished = true;
			          }
			      }
			  }
			  if (!selection_finished) {
			      if (selection_range.compareEndPoints("StartToEnd", selection_range) == 0) {
			          selection_finished = true;
			      } else {
			          selection_range.moveEnd("character", -1)
			          if (selection_range.text == selection_text) {
			              untrimmed_selection_text += "\r\n";
			          } else {
			              selection_finished = true;
			          }
			      }
			  }
			  if (!after_finished) {
			      if (after_range.compareEndPoints("StartToEnd", after_range) == 0) {
			          after_finished = true;
			      } else {
			          after_range.moveEnd("character", -1)
			          if (after_range.text == after_text) {
			              untrimmed_after_text += "\r\n";
			          } else {
			              after_finished = true;
			          }
			      }
			  }

			} while ((!before_finished || !selection_finished || !after_finished));

			return {start:untrimmed_before_text.length,end:untrimmed_before_text.length + untrimmed_selection_text.length};
		}
	}
})(jQuery);