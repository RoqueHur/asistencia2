(() => {
  const sidebar = document.querySelector('.sidebar');
  document.querySelectorAll('[data-menu-toggle]').forEach(button => {
    button.addEventListener('click', () => sidebar?.classList.toggle('open'));
  });

  document.querySelectorAll('[data-modal-open]').forEach(button => {
    button.addEventListener('click', () => {
      const modal = document.getElementById(button.dataset.modalOpen);
      if (modal) {
        modal.classList.add('show');
        modal.setAttribute('aria-hidden', 'false');
        document.body.classList.add('modal-open');
      }
    });
  });

  document.querySelectorAll('[data-modal-close]').forEach(button => {
    button.addEventListener('click', () => {
      const modal = button.closest('.modal');
      if (modal) {
        modal.classList.remove('show');
        modal.setAttribute('aria-hidden', 'true');
        document.body.classList.remove('modal-open');
      }
    });
  });

  document.querySelectorAll('[data-confirm]').forEach(link => {
    link.addEventListener('click', event => {
      if (!window.confirm(link.dataset.confirm)) event.preventDefault();
    });
  });

  document.querySelectorAll('[data-table-search]').forEach(input => {
    input.addEventListener('input', () => {
      const table = document.getElementById(input.dataset.tableSearch);
      const query = input.value.trim().toLowerCase();
      table?.querySelectorAll('tbody tr').forEach(row => {
        row.style.display = row.textContent.toLowerCase().includes(query) ? '' : 'none';
      });
    });
  });
})();

(() => {
  const clock = document.getElementById('live-clock');
  const pad = value => String(value).padStart(2, '0');
  const currentTime = () => {
    const now = new Date();
    return `${pad(now.getHours())}:${pad(now.getMinutes())}`;
  };

  if (clock) {
    const refreshClock = () => {
      const now = new Date();
      clock.textContent = `${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`;
    };
    refreshClock();
    window.setInterval(refreshClock, 1000);
  }

  const syncRowState = select => {
    const row = select.closest('[data-attendance-row]');
    if (row) row.dataset.status = select.value;
  };

  document.querySelectorAll('.attendance-status').forEach(select => {
    syncRowState(select);
    select.addEventListener('change', () => syncRowState(select));
  });

  document.querySelector('[data-mark-all-present]')?.addEventListener('click', () => {
    document.querySelectorAll('.attendance-status').forEach(select => {
      select.value = 'PRESENTE';
      syncRowState(select);
    });
    document.querySelectorAll('.table-time').forEach(input => { input.value = currentTime(); });
  });

  document.querySelector('[data-reset-attendance]')?.addEventListener('click', () => {
    const form = document.getElementById('attendance-list-form');
    form?.reset();
    document.querySelectorAll('.attendance-status').forEach(syncRowState);
  });
})();
