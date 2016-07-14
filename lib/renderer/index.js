import css from './css';
import scss from './scss';
import less from './less';
import helpers from '../support/helpers';
import _ from 'underscore';

let renderers = { 
  css: css,
  scss: scss,
  sass: scss,
  less: less
};

module.exports = {
	for: (file) => {
	  let extension = helpers.extname(file);
	  return renderers[extension];
	},

	supportedExtensions: () => {
	  return _.keys(renderers);
	},

	renderers: renderers
}