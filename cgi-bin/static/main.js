'use strict';

function debounce(callback, delay) {
	let id = null;
	return (...args) => {
		window.clearTimeout(id);
		id = window.setTimeout(() => {
			callback.apply(null, args);
		}, delay);
	 };
}

let contentModified = false;
let scrollX = 0;
let scrollY = 0;
async function applyContent() {
	const input = document.getElementById('content');
	const preview = document.getElementById('preview');
	const save = document.getElementById('save');
	save.disabled = !contentModified;
	if(contentModified) {
		save.innerText = 'Save';
	}
	try {
		scrollY = preview.contentWindow.scrollY;
		scrollX = preview.contentWindow.scrollX;
	} catch(e) {
		// cross-origin content doesn't allow scroll access
		// (user may have clicked a link)
	}
	
	const res = await fetch(document.body.dataset.scriptName.replace('edit.cgi', 'preview.cgi') + document.body.dataset.pathInfo, {
		method: 'POST',
		headers: {
			'Content-Type': 'text/gemini',
		},
		body: input.value,
	});
	if(res.status != 200) {
		alert('There was an error rendering the page.');
		const body = await res.text();
		throw new Error(body);
	}

	preview.addEventListener('load', function() {
		preview.contentWindow.scrollTo({top: scrollY, left: scrollX, behavior: 'instant'});
	}, {once: true});
	preview.srcdoc = await res.text();
}

let tmplFile;
let tmplDir;
let filesRoot;

function initFileTree() {
	while(filesRoot.lastChild) filesRoot.lastChild.remove();
	initDir([{name: 'Site', children: window.lichenFilesystem, root: true}], [], filesRoot);
}

function initFile(el, path, container) {
	const node = tmplFile.cloneNode(true).firstElementChild;
	node.lichenPath = Array.from(path);
	node.lichenName = el.name;
	const link = node.querySelector('a');
	link.innerText = el.name;
	if(el.name.endsWith('.gmi')) {
		link.setAttribute('href', document.body.dataset.scriptName + '/' + path.join('/'));
		link.classList.add('link--editable');
	} else {
		link.classList.add('link--unknown');
		link.setAttribute('href', document.body.dataset.scriptName.replace('/cgi-bin/edit.cgi', '') + '/' + path.join('/'));
		link.setAttribute('target', '_blank');
	}
	node.querySelector('button.action_insert-link').addEventListener('click', handleInsertLink);
	node.querySelector('button.action_file-delete').addEventListener('click', handleFileDelete);
	container.append(node);
}

function initDir(elements, path, container) {
	for(const el of elements) {
		if(!el.root) path.push(el.name);
		if(el.children) {
			const node = tmplDir.cloneNode(true).firstElementChild;
			node.lichenPath = Array.from(path);
			node.lichenName = el.name;
			if(el.root) {
				node.querySelector('details').setAttribute('open', true);
				node.querySelector('summary').classList.add('files-root');
			}
			const title = node.querySelector('summary span');
			title.innerText = el.name;
			node.querySelector('button.action_new-page').addEventListener('click', handleNewPage);
			node.querySelector('button.action_dir-create').addEventListener('click', handleNewDir);
			node.querySelector('button.action_upload').addEventListener('click', handleUpload);
			if(el.root) {
				node.querySelector('button.action_dir-delete').remove();
			} else {
				node.querySelector('button.action_dir-delete').addEventListener('click', handleDirDelete);
			}

			initDir(el.children, Array.from(path), node.querySelector('details ol'));
			container.append(node);
		} else {
			initFile(el, path, container);
		}
		if(!el.root) path.pop();
	}
}

function handleInsertLink(event) {
	const fileEl = event.target.closest('li');
	const content = document.getElementById('content');
	let path = fileEl.lichenPath.join('/');

	const [start, end] = [content.selectionStart, content.selectionEnd];
		content.setRangeText(`\n=> /${path} `, start, end, 'end');
	document.getElementById('panel_files').classList.toggle('hidden');
	document.getElementById('panel_editor').classList.toggle('hidden');
	content.focus();
	content.dispatchEvent(new Event('input'));
}

async function handleFileDelete(event) {
	const fileEl = event.target.closest('li');
	if(!confirm('Are you sure you want to delete ' + fileEl.lichenName + '?')) return;
	await deleteFile(fileEl.lichenPath.join('/'));
	fileEl.remove();
}

async function handleDirDelete(event) {
	const fileEl = event.target.closest('li');
	if(!confirm('Are you sure you want to delete ' + fileEl.lichenName + '?')) return;
	await deleteFile(fileEl.lichenPath.join('/'));
	fileEl.remove();
}

function handleUpload(event) {
	const fileEl = event.target.closest('li');
	uploadContext = fileEl;
	document.getElementById('upload').click();
}

function handleNewDir(event) {
	const name = prompt('New folder name:');
	if(!name || !name.length) return;
	const fileEl = event.target.closest('li');
	initDir([{name: name, children: []}], fileEl.lichenPath, fileEl.querySelector('details ol'));
}

function handleNewPage(event) {
	let filename = prompt('New page filename:');
	if(!filename) return;
	filename = filename.trim();
	if(!filename.endsWith('.gmi')) filename += '.gmi';

	const path = Array.from(event.target.closest('li').lichenPath);
	path.push(filename);
	window.location = document.body.dataset.scriptName + '/' + path.join('/');
}

window.addEventListener('DOMContentLoaded', applyContent, {once: true});
window.addEventListener('DOMContentLoaded', function() {
	const onContentInput = debounce(applyContent, 500);
	const input = document.getElementById('content');
	input.focus();
	input.addEventListener('input', onContentInput);
	input.addEventListener('input', function() {
		contentModified = true;
	});
	
	window.addEventListener('beforeunload', function(event) {
		if(!contentModified) return;
		event.preventDefault();
		return 'Unsaved changes will be lost.';
	});
	
	const preview = document.getElementById('preview');
	preview.addEventListener('load', function(event) {
		const warning = document.getElementById('nav-warning');
		try {
			const onContent = event.target.contentWindow.location.href == 'about:blank' || event.target.contentWindow.location.href == 'about:srcdoc';
			warning.style.display = onContent ? 'none' : 'flex';
		} catch(e) {
			warning.style.display = 'flex';
		}
	});

	document.getElementById('nav-return').addEventListener('click', function() {
		applyContent();
	});

	document.getElementById('toggle-help').addEventListener('click', function(event) {
		document.getElementById('help').classList.toggle('hidden');
	});

	function toggleFiles() {
		document.getElementById('panel_files').classList.toggle('hidden');
		document.getElementById('panel_editor').classList.toggle('hidden');
	}

	document.getElementById('toggle-editor').addEventListener('click', toggleFiles);
	document.getElementById('toggle-files').addEventListener('click', toggleFiles);

	document.getElementById('save').addEventListener('click', saveContent);
	document.addEventListener('keydown', function(event) {
		if((event.ctrlKey || event.metaKey) && event.key == 's') {
			event.preventDefault();
			saveContent();
		}
	});

	tmplFile = document.getElementById('tmpl_file').content;
	tmplDir = document.getElementById('tmpl_dir').content;
	filesRoot = document.getElementById('files').firstChild;

	initFileTree();

	document.getElementById('upload').addEventListener('change', uploadFile);
}, {once: true});


// --- API --- //

async function saveContent() {
	const input = document.getElementById('content');
	const button = document.getElementById('save');
	const content = document.getElementById('content');
	button.disabled = true;
	content.disabled = true;
	button.innerText = 'Saving...';

	const res = await fetch(document.body.dataset.scriptName.replace('edit.cgi', 'save.cgi') + document.body.dataset.pathInfo, {
		method: 'POST',
		headers: {
			'Content-Type': 'text/gemini',
		},
		body: input.value,
	});
	if(res.status != 204) {
		button.disabled = false;
		content.disabled = false;
		button.innerText = 'Save';
		const body = await res.text();
		alert('There was an error that prevented the file from being saved.');
		throw new Error(body);
	} else {
		button.disabled = true;
		content.disabled = false;
		button.innerText = 'Saved';
		contentModified = false;
	}
}

async function deleteFile(path) {
	const res = await fetch(document.body.dataset.scriptName.replace('edit.cgi', 'delete.cgi') + '/' + path, {
		method: 'POST',
	});
	if(res.status != 204) {
		const body = await res.text();
		alert('There was an error deleting the file.');
		throw new Error(body);
	}
}

function makeImage(file) {
	return new Promise((res, rej) => {
		const img = new Image();
		img.onload = function() { res(img); };
		img.src = URL.createObjectURL(file);
	});
}

function saveCanvasBlob(canvas, type, quality) {
	return new Promise((res, rej) => {
		canvas.toBlob(res, type, quality);
	});
}

function makeCanvas(image, width) {
	const ar = image.width / image.height;
	const canvas = document.createElement("canvas");
	canvas.width = width;
	canvas.height = image.height * ar;
	const ctx = canvas.getContext('2d');
	ctx.drawImage(image, 0, 0, width, image.height * ar);
	return canvas;
}


const IMAGE_RESIZE_TYPES = ['image/jpeg', 'image/png'];

let uploadContext;
async function uploadFile(event) {
	const overlay = document.getElementById('upload-overlay');
	overlay.classList.remove('hidden');
	try {
		let file = event.target.files[0];
		if(IMAGE_RESIZE_TYPES.includes(file.type)) {
			const image = await makeImage(file);
			const maxWidth = parseInt(document.body.dataset.imageMaxWidth);
			if(image.width > maxWidth && confirm(`This image is ${image.width}×${image.height} (${(file.size / 1000000).toFixed(1)} MB). Would you like to resize it to ${maxWidth} pixels wide to save bandwidth?`)) {
				const canvas = makeCanvas(image, maxWidth);
				const blob = await saveCanvasBlob(canvas, image.type);
				file = new File([blob], file.name, {type: image.type});
			}
		}

		const ctxPath = Array.from(uploadContext.lichenPath);
		ctxPath.push(file.name);
		const res = await fetch(document.body.dataset.scriptName.replace('edit.cgi', 'upload.cgi') + '/' + ctxPath.join('/'), {
			method: 'POST',
			body: file,
		});

		if(res.status != 204) {
			const body = await res.text();
			alert('There was an error uploading the file:\n\n' + body);
			throw new Error(body);
		}

		const filename = res.headers.get('x-file-name');
		const fullPath = Array.from(uploadContext.lichenPath);
		fullPath.push(filename);
		initFile({name: filename}, fullPath, uploadContext.querySelector('details ol'));
	} catch(e) {
		throw new Error(e);
	} finally {
		overlay.classList.add('hidden');
	}
}