$(function(){		
	$('.portfolio_overlay').stop().animate({opacity : '0'}, 1);
	/*Input Script*/
	$('input[type=text]').focus(function() {
		if($(this).attr('readonly') || $(this).attr('readonly') == 'readonly') return false;
		if ($(this).val() === $(this).attr('title')) {
				$(this).val('');
		}   
		}).blur(function() {
		if($(this).attr('readonly') || $(this).attr('readonly') == 'readonly') return false;
		if ($(this).val().length === 0) {
			$(this).val($(this).attr('title'));
		}                        
	});
	
	$('textarea').focus(function() {
		if ($(this).text() === $(this).attr('title')) {
				$(this).text('');
			}        
		}).blur(function() {
		if ($(this).text().length === 0) {
			$(this).text($(this).attr('title'));
		}                        
	});
	/*Menu */
	menu_first = $('ul.mainmenu').find('li:first');
	menu_last = $('ul.mainmenu').find('li:last');
	menu_second = menu_first.next('li');
	menu_first.addClass('first');
	menu_second.addClass('second');
	menu_last.addClass('last');
	$('ul.mainmenu').find('li:even').addClass('even');

	/*Portfolio Overlay*/
	$('.portfolio li').hover(function(){
		$(this).find('.portfolio_overlay').stop().animate({opacity : '1'}, 400);
	}, function(){
		$(this).find('.portfolio_overlay').stop().animate({opacity : '0'}, 400);
	});	
	
	/*Filter*/
	$('.filter_list a').click(function(){
		$('.filter_list li').removeClass('act');
		$(this).parent('li').addClass('act');
		filter_class = $(this).attr('rel');
		dm_filter('.portfolio', 'li', filter_class, '1750');
		
	});
});

function dm_filter($obj, $elem_type, $filter, $timer) {
	$half = $timer/2;	
	if ($filter == "*") {		
		$($obj).find($elem_type).show($timer);
		//$($obj).find('li').removeClass('odd');
		//$($obj).find('li:visible').filter(':odd').addClass('odd');
		
	}
	else {
		$($obj).find($elem_type).not($filter).hide($half, function(){
			$($obj).find($filter).show($timer, function(){
				//$($obj).find('li').removeClass('odd');
				//$($obj).find('li:visible').filter(':odd').addClass('odd');
			});							
		});
	}
}