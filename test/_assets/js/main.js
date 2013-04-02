(function (document, SOME_FRAMEWORK) {
	function write(msg) {
		var ele = document.getElementById('message');
		if (ele) {
			ele.innerHTML = msg;
		}
	}

	if (SOME_FRAMEWORK) {
		write(SOME_FRAMEWORK.toUpper('<em>some framework</em> <strong>exists</strong>!'));
	} else {
		write('<em>SOME_FRAMEWORK</em> does <strong>not exist</strong>.');
	}
}(this.document, this.SOME_FRAMEWORK));