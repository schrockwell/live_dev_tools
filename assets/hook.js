export default {
  mounted() {
    this.components = [];

    this.timer = setInterval(() => {
      const newComponents = [];

      document.querySelectorAll("[data-phx-component]").forEach((el) => {
        const cid = parseInt(el.dataset.phxComponent);
        const id = el.getAttribute("id");
        const parentEl = el.parentElement.closest("[data-phx-component]");

        let parentCid = null;
        if (parentEl) {
          parentCid = parseInt(parentEl.dataset.phxComponent);
        }

        newComponents.push({ cid, dom_id: id, parent_cid: parentCid });
      });

      if (newComponents.length != this.components.length) {
        this.putNewComponents(newComponents);
      } else {
        for (let i = 0; i < this.components.length; i++) {
          if (this.components[i].cid !== newComponents[i].cid) {
            this.putNewComponents(newComponents);
            break;
          }
        }
      }
    }, 1000);
  },

  destroyed() {
    clearInterval(this.timer);
  },

  putNewComponents(newComponents) {
    this.pushEvent("__dom_components__", { components: newComponents });
    this.components = newComponents;
    console.log("new components", newComponents);
  },
};
