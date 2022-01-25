export const InitToast = {
  mounted() {
    init()
  }
}

const init = () => {
  const toastEl = document.querySelector('.toast')
  if (toastEl && toastEl.innerText !== '') {
    toastEl.classList.add("mr-4")

    setTimeout(() => {
      toastEl.classList.toggle("-mr-88", "mr-4")
    }, 2000);
  }
}

init()
