var SOME_FRAMEWORK=function(){return{version:"0.0.1",toUpper:function(e){return e.toUpperCase()}}}();(function(e,t){function n(t){var n=e.getElementById("message");n&&(n.innerHTML=t)}t?n(t.toUpper("<em>some framework</em> <strong>exists</strong>!")):n("<em>SOME_FRAMEWORK</em> does <strong>not exist</strong>.")})(this.document,this.SOME_FRAMEWORK);