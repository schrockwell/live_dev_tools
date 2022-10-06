export default {
  mounted() {
    this.cids = [];

    this.timer = setInterval(() => {
      const newCids = [];

      document
        .querySelectorAll("[data-phx-component]")
        .forEach((el) => newCids.push(parseInt(el.dataset.phxComponent)));

      if (newCids.length != this.cids.length) {
        this.putNewCids(newCids);
      } else {
        for (let i = 0; i < this.cids.length; i++) {
          if (this.cids[i] !== newCids[i]) {
            this.putNewCids(newCids);
            break;
          }
        }
      }
    }, 1000);
  },

  destroyed() {
    clearInterval(this.timer);
  },

  putNewCids(newCids) {
    this.pushEvent("__new_cids__", { cids: newCids });
    this.cids = newCids;
    // console.log("new cids", newCids);
  },
};
