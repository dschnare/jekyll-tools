(function (document, SOME_FRAMEWORK) {
	function write(msg) {
		var ele = document.getElementById('message');
		if (ele) {
			ele.innerHTML = msg;
		}
	}

	if (SOME_FRAMEWORK) {
		write(SOME_FRAMEWORK.toUpper('some framework exists!'));
	} else {
		write('SOME_FRAMEWORK does not exist.');
	}
}(this.document, this.SOME_FRAMEWORK));