function Dialog(element) {
    this.element = element;
    this.content = element.querySelector('.content');

    this.clear = function() {
        while (this.content.lastChild != null) {
            this.content.removeChild(this.content.lastChild);
        }
    };

    this.addTitle = function(title) {
        var t = document.createElement('h3');
        t.textContent = title;
        this.content.appendChild(t);
    };

    this.addText = function(text) {
        var t = document.createElement('p');
        t.innerHTML = text;
        this.content.appendChild(t);
    };

    this.display = function(maxTop) {
        if (maxTop === null || maxTop === undefined) {
            maxTop = 150;
        }

        this.element.classList.toggle('hide-me');
        var x = window.innerWidth / 2;
        x = x - (this.element.offsetWidth / 2);
        if (x < 0) {
            x = 0;
        }
        var y = window.innerHeight / 2;
        y = y - (this.element.offsetHeight / 2);
        if (y < 0) {
            y = 0;
        } else if (y > maxTop) {
            y = maxTop;
        }

        this.element.style.top = '' + y + 'px';
        this.element.style.left = '' + x + 'px';
    }
}