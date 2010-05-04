$(document).ready(function(){
  /*
  This is adapted from Sam & Zach -
  http://buildinternet.com/2009/01/how-to-make-a-smooth-animated-menu-with-jquery/

  The use of stop() below is per -
  http://www.learningjquery.com/2009/01/quick-tip-prevent-animation-queue-buildup/

  @todo maybe make it a jquery poogin
  */

  $("a").click(function(){   //Remove outline from links
    $(this).blur();
  });

  var puts = console.log ? console.log : function(){};

  var shortHeight = '0px' // weird

  var setupMouseoverMenu = null;

  var setupMouseover = function(hotspot, menu){
    var bgcolor = menu.css('background-color')
    var height = menu.height();
    var useHeight = height+'px'
    menu.css('background','none');
    menu.height(shortHeight);
    menu.data('inMenu', false);
    menu.data('showing', false);
    setupMouseoverHotspot(hotspot, menu, bgcolor, useHeight);
    setupMouseoverMenu(menu);
  };

  setupMouseoverMenu = function(menu){
    menu.mouseover(function(){
      if (menu.data('showing')){
        puts("> menu mouseover - showing:true so inMenu:true.");
        menu.data('inMenu', true);
      } else {
        puts("> menu mouseover - showing:false so stay.");
      }
    });
  };

  var setupMouseoverHotspot = function(hotspot, menu, bgcolor, useHeight) {
    hotspot.mouseover(function(){
      if (menu.data('showing')){
        puts('> hs mouseover - showing:true so stay.');
      } else {
        puts('> hs mouseover - showing:false so showing:true with actions.');
        menu.data('showing', true);
        menu.css({
          'background-color' : bgcolor,
          'opacity'          : 1
        });
        menu.stop().animate(
          { height : useHeight },
          { queue:false, duration:600, easing: 'easeOutBounce' }
        );
      }
    });
  };

  var closeMenuFunction = function(menu) {
    return function(){
      if (! menu.data('showing')){
        puts("> close() - showing:false so stay");
      } else {
        puts("> close() - showing:true so (showing:false, inMenu:false) with actions.");
        menu.data('showing', false);
        menu.data('inMenu', false);
        menu.stop().animate(
          { height:shortHeight },
          { queue:false,
            duration:600,
            easing: 'easeOutBounce'
          }
        );
        menu.animate(
          { opacity:0 },
          { queue: false, duration: 600 }
        )
      };
    }
  };

  var setupMouseout = function(hotspot, menu){
    close = closeMenuFunction(menu);
    hotspot.mouseout(function(){
      // hack: give a few beats to wait and see whether we drag
      // the mouse into the dropdown menu or off of the hotspot, off of the menu
      setTimeout(function(){
        if (menu.data('inMenu')) {
          puts("> hotspot mouseout - inMenu:true so stay.");
        } else {
          puts("> hotspot mouseout - inMenu:false so close.");
          close();
        }
      }, 1000);
    });
    menu.mouseout(function(){
      puts("> menu mouseout - close() definately.")
      close();
    });
  };

  els = $('.bouncy-lvl2-menu');
  for (var i=els.length; i--;) {
    var menu = $(els[i]);
    var sepDiv = menu.parent();
    var hotspot = sepDiv.prev().find('a');
    setupMouseover(hotspot, menu);
    setupMouseout(hotspot, menu);
  }

});