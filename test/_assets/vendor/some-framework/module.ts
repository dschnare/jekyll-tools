module SOME_FRAMEWORK {
	export var version = '0.0.1';
	export function toUpper(s:string):string {
		'use strict';
		return s.toUpperCase() + 4;
	}
}