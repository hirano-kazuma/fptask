// カレンダー機能
function initCalendar() {
  const calendarContainer = document.getElementById('calendar-container');
  if (!calendarContainer) return;

  // data属性から既存の予約枠を取得
  const existingSlots = JSON.parse(calendarContainer.dataset.existingSlots || '[]');

  // 編集モードかどうかを判定
  const editingTimeSlotData = calendarContainer.dataset.editingTimeSlot;
  const editingTimeSlot = editingTimeSlotData && editingTimeSlotData !== 'null' ? JSON.parse(editingTimeSlotData) : null;
  const isEditMode = !!editingTimeSlot;

  // 閲覧モードかどうかを判定
  const isViewMode = calendarContainer.dataset.viewMode === 'true';

  // エラーメッセージ表示
  function showError(message) {
    const existingAlert = document.getElementById('error-alert');
    if (existingAlert) existingAlert.remove();

    const alert = document.createElement('div');
    alert.id = 'error-alert';
    alert.className = 'alert alert-danger alert-dismissible fade show position-fixed top-0 start-50 translate-middle-x mt-3';
    alert.style.zIndex = '9999';
    alert.innerHTML = `
      ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    document.body.appendChild(alert);

    setTimeout(() => {
      alert.remove();
    }, 3000);
  }

  let currentYear, currentMonth;
  let selectedDate = null;

  const calendarGrid = document.getElementById('calendar-grid');
  const currentMonthEl = document.getElementById('current-month');
  const prevMonthBtn = document.getElementById('prev-month');
  const nextMonthBtn = document.getElementById('next-month');
  const selectedDateHeader = document.getElementById('selected-date-header');
  const timeSlotsContainer = document.getElementById('time-slots-container');
  const form = document.getElementById('time-slot-form');
  const hiddenStartTime = document.getElementById('hidden-start-time');
  const hiddenEndTime = document.getElementById('hidden-end-time');

  // 初期化
  const today = new Date();
  currentYear = today.getFullYear();
  currentMonth = today.getMonth();

  // URLパラメータから日付を取得、または編集モードの場合は編集対象の日付を使用
  const urlParams = new URLSearchParams(window.location.search);
  const dateParam = urlParams.get('date');

  if (dateParam) {
    const [year, month, day] = dateParam.split('-').map(Number);
    currentYear = year;
    currentMonth = month - 1;
    selectedDate = new Date(year, month - 1, day);
  } else if (isEditMode && editingTimeSlot.start_time) {
    // 編集モードの場合、編集対象の日付を初期選択
    // UTC時間の文字列から日付部分を直接抽出（タイムゾーンの影響を避ける）
    const slotTimeStr = editingTimeSlot.start_time.replace('.000Z', '').replace('Z', '');
    const dateMatch = slotTimeStr.match(/^(\d{4})-(\d{2})-(\d{2})/);
    if (dateMatch) {
      const [, year, month, day] = dateMatch;
      currentYear = parseInt(year);
      currentMonth = parseInt(month) - 1;
      selectedDate = new Date(currentYear, currentMonth, parseInt(day));
    }
  }

  renderCalendar();

  if (selectedDate) {
    setTimeout(() => {
      const dayElements = document.querySelectorAll('.calendar-day:not(.empty):not(.disabled)');
      dayElements.forEach(el => {
        if (parseInt(el.textContent) === selectedDate.getDate()) {
          el.classList.add('selected');
        }
      });
      renderTimeSlots();

      // 編集モードの場合、編集対象の時間枠を初期選択状態にし、フォームに初期値を設定
      if (isEditMode && editingTimeSlot.start_time && editingTimeSlot.end_time && hiddenStartTime && hiddenEndTime) {
        // フォームに初期値を設定（UTC時間をローカル時間の形式に変換）
        const startDate = new Date(editingTimeSlot.start_time);
        const endDate = new Date(editingTimeSlot.end_time);

        const formatDateTime = (date) => {
          const year = date.getFullYear();
          const month = String(date.getMonth() + 1).padStart(2, '0');
          const day = String(date.getDate()).padStart(2, '0');
          const hours = String(date.getHours()).padStart(2, '0');
          const minutes = String(date.getMinutes()).padStart(2, '0');
          return `${year}-${month}-${day}T${hours}:${minutes}:00`;
        };

        hiddenStartTime.value = formatDateTime(startDate);
        hiddenEndTime.value = formatDateTime(endDate);

        // 編集対象の時間枠をハイライト
        const editingSlotTimeStr = editingTimeSlot.start_time.replace('.000Z', '').replace('Z', '');
        const timeMatch = editingSlotTimeStr.match(/T(\d{2}):(\d{2}):/);
        if (timeMatch) {
          const [, hour, minute] = timeMatch;
          const timeBtn = Array.from(document.querySelectorAll('.time-slot-btn')).find(btn => {
            const btnTime = btn.textContent.match(/(\d{2}):(\d{2})/);
            return btnTime && btnTime[1] === hour && btnTime[2] === minute;
          });
          if (timeBtn) {
            timeBtn.classList.add('active');
            timeBtn.style.borderWidth = '3px';
          }
        }
      }
    }, 0);
  }

  prevMonthBtn.addEventListener('click', function() {
    currentMonth--;
    if (currentMonth < 0) {
      currentMonth = 11;
      currentYear--;
    }
    renderCalendar();
  });

  nextMonthBtn.addEventListener('click', function() {
    currentMonth++;
    if (currentMonth > 11) {
      currentMonth = 0;
      currentYear++;
    }
    renderCalendar();
  });

  function renderCalendar() {
    const dayNames = ['日', '月', '火', '水', '木', '金', '土'];
    currentMonthEl.textContent = `${currentYear}年${currentMonth + 1}月`;

    calendarGrid.innerHTML = '';

    dayNames.forEach((name, i) => {
      const el = document.createElement('div');
      el.className = 'calendar-day-header';
      if (i === 0) el.classList.add('sunday');
      if (i === 6) el.classList.add('saturday');
      el.textContent = name;
      calendarGrid.appendChild(el);
    });

    const firstDay = new Date(currentYear, currentMonth, 1);
    const lastDay = new Date(currentYear, currentMonth + 1, 0);
    const startDayOfWeek = firstDay.getDay();
    const daysInMonth = lastDay.getDate();

    const todayDate = new Date();
    todayDate.setHours(0, 0, 0, 0);

    for (let i = 0; i < startDayOfWeek; i++) {
      const el = document.createElement('div');
      el.className = 'calendar-day empty';
      calendarGrid.appendChild(el);
    }

    for (let day = 1; day <= daysInMonth; day++) {
      const date = new Date(currentYear, currentMonth, day);
      const dayOfWeek = date.getDay();
      const el = document.createElement('div');
      el.className = 'calendar-day';
      el.textContent = day;

      if (date.getTime() === todayDate.getTime()) {
        el.classList.add('today');
      }

      if (date < todayDate || dayOfWeek === 0) {
        el.classList.add('disabled');
      } else {
        const hasSlots = existingSlots.some(slot => {
          // UTC時間の文字列から日付部分を抽出して比較（タイムゾーンの影響を避ける）
          const slotTimeStr = slot.start_time.replace('.000Z', '').replace('Z', '');
          const slotDateMatch = slotTimeStr.match(/^(\d{4})-(\d{2})-(\d{2})/);
          if (!slotDateMatch) return false;

          const [, slotYear, slotMonth, slotDay] = slotDateMatch;
          return parseInt(slotYear) === currentYear &&
                 parseInt(slotMonth) - 1 === currentMonth &&
                 parseInt(slotDay) === day;
        });
        if (hasSlots) {
          el.classList.add('has-slots');
        }

        el.addEventListener('click', function() {
          document.querySelectorAll('.calendar-day.selected').forEach(d => d.classList.remove('selected'));
          el.classList.add('selected');
          selectedDate = new Date(currentYear, currentMonth, day);
          renderTimeSlots();
        });
      }

      calendarGrid.appendChild(el);
    }
  }

  function renderTimeSlots() {
    if (!selectedDate) return;

    const dayOfWeek = selectedDate.getDay();
    const dayNames = ['日', '月', '火', '水', '木', '金', '土'];
    const year = selectedDate.getFullYear();
    const month = selectedDate.getMonth() + 1;
    const day = selectedDate.getDate();
    const dateStr = `${year}/${month}/${day}（${dayNames[dayOfWeek]}）`;

    selectedDateHeader.textContent = dateStr;

    let startHour, endHour;
    if (dayOfWeek === 6) {
      startHour = 11;
      endHour = 15;
    } else {
      startHour = 10;
      endHour = 18;
    }

    timeSlotsContainer.innerHTML = '';

    const info = document.createElement('p');
    info.className = 'text-muted mb-3';
    info.textContent = `営業時間: ${startHour}:00〜${endHour}:00`;
    timeSlotsContainer.appendChild(info);

    const slotsDiv = document.createElement('div');
    slotsDiv.className = 'd-flex flex-wrap gap-2';

    for (let hour = startHour; hour < endHour; hour++) {
      for (let min = 0; min < 60; min += 30) {
        const timeStr = `${String(hour).padStart(2, '0')}:${String(min).padStart(2, '0')}`;
        const checkTimeStr = `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}T${timeStr}:00`;

        // 既存の予約枠を検索（IDも含める）
        const existingSlot = existingSlots.find(slot => {
          const slotTimeStr = slot.start_time.replace('.000Z', '').replace('Z', '');
          return slotTimeStr === checkTimeStr;
        });
        const isExisting = !!existingSlot;

        // 編集対象の枠かどうかを判定
        const isEditingSlot = isEditMode && editingTimeSlot.start_time && (() => {
          const editingSlotTimeStr = editingTimeSlot.start_time.replace('.000Z', '').replace('Z', '');
          return editingSlotTimeStr === checkTimeStr;
        })();

        const btn = document.createElement('button');
        btn.type = 'button';

        if (isEditingSlot) {
          // 編集対象の枠は特別なスタイル
          btn.className = 'btn btn-warning time-slot-btn';
          btn.textContent = `✏️ ${timeStr}`;
          btn.title = 'この時間枠を編集中です。別の時間を選択して更新できます。';
        } else if (isViewMode) {
          // 閲覧モードの場合
          if (isExisting) {
            btn.className = 'btn btn-info time-slot-btn';
            btn.textContent = `ℹ️ ${timeStr}`;
            btn.title = 'クリック: 詳細表示 / Ctrl+クリック: 削除';
          } else {
            btn.className = 'btn btn-outline-secondary time-slot-btn';
            btn.textContent = `◯ ${timeStr}`;
            btn.title = '予約枠がありません';
            btn.disabled = true;
          }
        } else {
          // 作成・編集モード
          btn.className = isExisting
            ? 'btn btn-success time-slot-btn'
            : 'btn btn-outline-primary time-slot-btn';
          btn.textContent = isExisting ? `✓ ${timeStr}` : `◯ ${timeStr}`;
          btn.title = isExisting ? 'この時間枠は既に作成済みです' : (isEditMode ? 'クリックして予約枠を更新' : 'クリックして予約枠を作成');
        }

        btn.addEventListener('click', function(e) {
          // 閲覧モードの場合
          if (isViewMode) {
            if (isExisting && existingSlot.id) {
              // 右クリックまたはCtrl+クリックで削除確認
              if (e.ctrlKey || e.metaKey) {
                e.preventDefault();
                if (confirm(`${dateStr} ${timeStr} の予約枠を削除しますか？`)) {
                  // Turboを使って削除リクエストを送信
                  const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
                  fetch(`/time_slots/${existingSlot.id}`, {
                    method: 'DELETE',
                    headers: {
                      'X-CSRF-Token': csrfToken,
                      'Content-Type': 'application/json',
                      'Accept': 'text/html'
                    },
                    credentials: 'same-origin'
                  }).then(response => {
                    if (response.ok) {
                      // ページをリロードしてカレンダーを更新
                      window.location.reload();
                    } else {
                      alert('削除に失敗しました');
                    }
                  }).catch(error => {
                    console.error('Error:', error);
                    alert('削除中にエラーが発生しました');
                  });
                }
              } else {
                // 通常のクリックで詳細ページに遷移
                window.location.href = `/time_slots/${existingSlot.id}`;
              }
            }
            return;
          }

          // 作成・編集モードの場合
          if (isExisting && !isEditingSlot) {
            showError('この時間枠は既に作成済みです');
            return;
          }

          // フォームが存在しない場合は処理しない（閲覧モード）
          if (!form || !hiddenStartTime || !hiddenEndTime) {
            return;
          }

          const actionText = isEditMode ? '更新' : '作成';
          if (confirm(`${dateStr} ${timeStr} の予約枠を${actionText}しますか？`)) {
            const startTimeStr = `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}T${timeStr}:00`;
            const endDate = new Date(year, month - 1, day, hour, min + 30);
            const endTimeStr = `${endDate.getFullYear()}-${String(endDate.getMonth() + 1).padStart(2, '0')}-${String(endDate.getDate()).padStart(2, '0')}T${String(endDate.getHours()).padStart(2, '0')}:${String(endDate.getMinutes()).padStart(2, '0')}:00`;

            hiddenStartTime.value = startTimeStr;
            hiddenEndTime.value = endTimeStr;
            form.submit();
          }
        });

        slotsDiv.appendChild(btn);
      }
    }

    timeSlotsContainer.appendChild(slotsDiv);
  }
}

// Turbo対応: ページ遷移時も初期化
document.addEventListener('DOMContentLoaded', initCalendar);
document.addEventListener('turbo:load', initCalendar);
