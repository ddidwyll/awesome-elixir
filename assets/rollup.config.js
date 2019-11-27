import svelte from 'rollup-plugin-svelte';
import resolve from 'rollup-plugin-node-resolve';
import commonjs from 'rollup-plugin-commonjs';
import livereload from 'rollup-plugin-livereload';
import { terser } from 'rollup-plugin-terser';
import css from 'rollup-plugin-css-only'

const production = !process.env.ROLLUP_WATCH;

export default {

	input: './js/app.js',
	output: {
		sourcemap: true,
		format: 'iife',
		name: 'app',
		file: '../priv/static/js/app.js'
	},
	plugins: [
		svelte({
			dev: !production,
			hydratable: true,
			legacy: true
		}),
		resolve({
			browser: true,
			dedupe: importee => importee === 'svelte' || importee.startsWith('svelte/')
		}),
		commonjs(),
    css({ output: '../priv/static/css/app.css' }),
		!production && livereload('../priv/static'),
		production && terser()
	],
	watch: {
		clearScreen: false
	}
};

