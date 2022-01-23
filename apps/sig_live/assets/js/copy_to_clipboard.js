export const CopyToClipboard = {
  mounted() {
		this.el.addEventListener('click', e => {
			const el = document.getElementById('content-to-copy');
			const buttonText = e.target.innerText

			navigator.clipboard.writeText(el.innerText).then(
				function() {
					e.target.innerText = 'COPIADO!'
					
					setTimeout(() => {e.target.innerText = buttonText}, 1000)
				}
			)
		})
  }
}
