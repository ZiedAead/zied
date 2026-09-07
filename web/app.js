/**
 * تطبيق زيد اياد للديون - محرك العمليات وقاعدة البيانات المحلية
 */

// =============================================================================
// حالة التطبيق والبيانات الافتراضية
// =============================================================================
const STORAGE_KEY = 'zied_debts_pwa_data';

const DEFAULT_STATE = {
  exchangeRate: 1530,
  persons: [
    {
      id: 1,
      name: "أحمد علي حسن",
      phone: "07701234567",
      notes: "صديق العمل - مكتب المنصور",
      createdAt: new Date(Date.now() - 15 * 86400000).toISOString()
    },
    {
      id: 2,
      name: "محمود الكرخي",
      phone: "07809876543",
      notes: "مورد أجهزة كهربائية",
      createdAt: new Date(Date.now() - 20 * 86400000).toISOString()
    },
    {
      id: 3,
      name: "عمر البغدادي",
      phone: "07505554433",
      notes: "حساب متوازن",
      createdAt: new Date(Date.now() - 30 * 86400000).toISOString()
    }
  ],
  transactions: [
    {
      id: 1,
      personId: 1,
      type: "for_me",
      amount: 250000,
      currency: "IQD",
      date: new Date(Date.now() - 14 * 86400000).toISOString().split('T')[0],
      notes: "سلفة شراء حاسوب"
    },
    {
      id: 2,
      personId: 1,
      type: "for_me",
      amount: 150,
      currency: "USD",
      date: new Date(Date.now() - 10 * 86400000).toISOString().split('T')[0],
      notes: "دفع اشتراك سيرفر"
    },
    {
      id: 3,
      personId: 2,
      type: "on_me",
      amount: 500000,
      currency: "IQD",
      date: new Date(Date.now() - 18 * 86400000).toISOString().split('T')[0],
      notes: "متبقي فاتورة تجهيز شاشات"
    },
    {
      id: 4,
      personId: 2,
      type: "on_me",
      amount: 200,
      currency: "USD",
      date: new Date(Date.now() - 5 * 86400000).toISOString().split('T')[0],
      notes: "طلب بضاعة من دبي"
    },
    {
      id: 5,
      personId: 3,
      type: "for_me",
      amount: 100000,
      currency: "IQD",
      date: new Date(Date.now() - 25 * 86400000).toISOString().split('T')[0],
      notes: "دين سابق"
    },
    {
      id: 6,
      personId: 3,
      type: "on_me",
      amount: 100000,
      currency: "IQD",
      date: new Date(Date.now() - 2 * 86400000).toISOString().split('T')[0],
      notes: "تسديد كامل المبلغ نقداً"
    }
  ]
};

// =============================================================================
// إدارة قاعدة البيانات المحلية LocalStorage
// =============================================================================
class DebtDatabase {
  static load() {
    try {
      const data = localStorage.getItem(STORAGE_KEY);
      if (data) {
        return JSON.parse(data);
      }
    } catch (e) {
      console.error("خطأ في قراءة البيانات المحلية:", e);
    }
    // في أول فتح للتطبيق، حفظ البيانات الافتراضية
    DebtDatabase.save(DEFAULT_STATE);
    return JSON.parse(JSON.stringify(DEFAULT_STATE));
  }

  static save(state) {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    } catch (e) {
      console.error("خطأ في حفظ البيانات المحلية:", e);
    }
  }

  static reset() {
    DebtDatabase.save(DEFAULT_STATE);
    return JSON.parse(JSON.stringify(DEFAULT_STATE));
  }

  static clear() {
    const emptyState = { exchangeRate: 1530, persons: [], transactions: [] };
    DebtDatabase.save(emptyState);
    return emptyState;
  }
}

// المتغير العام لحالة التطبيق
let appState = DebtDatabase.load();
let currentFilter = 'ALL';
let activePersonId = null;

// =============================================================================
// أدوات الحساب والتنسيق
// =============================================================================
function formatNumber(num) {
  return new Intl.NumberFormat('en-US').format(Math.round(num));
}

function formatDecimal(num) {
  return new Intl.NumberFormat('en-US', { minimumFractionDigits: 0, maximumFractionDigits: 2 }).format(num);
}

function formatIqd(amount) {
  return `${formatNumber(Math.abs(amount))} د.ع`;
}

function formatUsd(amount) {
  return `$${formatDecimal(Math.abs(amount))}`;
}

// حساب أرصدة شخص محدد
function calculatePersonBalances(personId) {
  const txs = appState.transactions.filter(t => t.personId === personId);
  let netIqd = 0, netUsd = 0;
  let forMeIqd = 0, onMeIqd = 0;
  let forMeUsd = 0, onMeUsd = 0;

  txs.forEach(t => {
    const amt = parseFloat(t.amount) || 0;
    if (t.currency === 'IQD') {
      if (t.type === 'for_me') {
        netIqd += amt;
        forMeIqd += amt;
      } else {
        netIqd -= amt;
        onMeIqd += amt;
      }
    } else {
      if (t.type === 'for_me') {
        netUsd += amt;
        forMeUsd += amt;
      } else {
        netUsd -= amt;
        onMeUsd += amt;
      }
    }
  });

  return {
    netIqd,
    netUsd,
    forMeIqd,
    onMeIqd,
    forMeUsd,
    onMeUsd,
    hasIqd: Math.abs(netIqd) > 0.01,
    hasUsd: Math.abs(netUsd) > 0.01,
    isSettled: Math.abs(netIqd) <= 0.01 && Math.abs(netUsd) <= 0.01,
    txCount: txs.length
  };
}

// حساب الإجماليات العامة للتطبيق
function calculateGlobalTotals() {
  let forMeIqd = 0, onMeIqd = 0;
  let forMeUsd = 0, onMeUsd = 0;

  appState.transactions.forEach(t => {
    const amt = parseFloat(t.amount) || 0;
    if (t.currency === 'IQD') {
      if (t.type === 'for_me') forMeIqd += amt;
      else onMeIqd += amt;
    } else {
      if (t.type === 'for_me') forMeUsd += amt;
      else onMeUsd += amt;
    }
  });

  const netIqd = forMeIqd - onMeIqd;
  const netUsd = forMeUsd - onMeUsd;
  const equivalentTotal = netIqd + (netUsd * appState.exchangeRate);

  return {
    forMeIqd,
    onMeIqd,
    forMeUsd,
    onMeUsd,
    netIqd,
    netUsd,
    equivalentTotal
  };
}

// =============================================================================
// عرض وتحديث واجهات المستخدم (UI Rendering)
// =============================================================================
function renderDashboard() {
  const totals = calculateGlobalTotals();

  // تحديث بطاقة الملخص
  document.getElementById('displayExchangeRate').textContent = formatNumber(appState.exchangeRate);
  document.getElementById('settingRateInput').value = appState.exchangeRate;

  const totalEqEl = document.getElementById('totalEquivalent');
  totalEqEl.textContent = formatIqd(totals.equivalentTotal);
  if (totals.equivalentTotal >= 0) {
    totalEqEl.style.color = '#FFFFFF';
  } else {
    totalEqEl.style.color = 'var(--red-on-me)';
  }

  document.getElementById('statForMeIqd').textContent = formatIqd(totals.forMeIqd);
  document.getElementById('statOnMeIqd').textContent = formatIqd(totals.onMeIqd);
  document.getElementById('statForMeUsd').textContent = formatUsd(totals.forMeUsd);
  document.getElementById('statOnMeUsd').textContent = formatUsd(totals.onMeUsd);

  renderPersonsList();
}

function renderPersonsList() {
  const container = document.getElementById('personsList');
  const search = document.getElementById('searchInput').value.trim().toLowerCase();

  let filtered = appState.persons.filter(person => {
    // فلتر البحث
    const matchSearch = person.name.toLowerCase().includes(search) ||
                        (person.phone && person.phone.includes(search));
    if (!matchSearch) return false;

    // فلتر الحالة
    const bal = calculatePersonBalances(person.id);
    if (currentFilter === 'FOR_ME') return bal.netIqd > 0 || bal.netUsd > 0;
    if (currentFilter === 'ON_ME') return bal.netIqd < 0 || bal.netUsd < 0;
    if (currentFilter === 'SETTLED') return bal.isSettled;
    return true;
  });

  document.getElementById('countAll').textContent = appState.persons.length;
  document.getElementById('filteredCountLabel').textContent = `${filtered.length} شخص`;

  if (filtered.length === 0) {
    container.innerHTML = `
      <div style="text-align: center; padding: 40px 20px; color: var(--text-secondary);">
        <div style="font-size: 40px; margin-bottom: 10px;">🔍</div>
        <strong style="display: block; font-size: 16px; color: #FFF; margin-bottom: 6px;">لا توجد حسابات مطابقة</strong>
        <p style="font-size: 13px;">اضغط على زر الإضافة بالأسفل لتسجيل شخص جديد.</p>
      </div>
    `;
    return;
  }

  container.innerHTML = filtered.map(person => {
    const bal = calculatePersonBalances(person.id);
    const initial = person.name ? person.name.charAt(0) : "؟";

    let badgesHtml = '';
    if (bal.isSettled) {
      badgesHtml = `<div class="bal-badge bal-badge-settled">✓ خالص الذمة (متوازن)</div>`;
    } else {
      let iqdBadge = '';
      let usdBadge = '';

      if (bal.hasIqd) {
        const isForMe = bal.netIqd > 0;
        const cls = isForMe ? 'bal-badge-green' : 'bal-badge-red';
        const label = isForMe ? 'لي: +' : 'علي: -';
        iqdBadge = `<div class="bal-badge ${cls}">${label} ${formatIqd(bal.netIqd)}</div>`;
      }

      if (bal.hasUsd) {
        const isForMe = bal.netUsd > 0;
        const cls = isForMe ? 'bal-badge-green' : 'bal-badge-red';
        const label = isForMe ? 'لي: +' : 'علي: -';
        usdBadge = `<div class="bal-badge ${cls}">${label} ${formatUsd(bal.netUsd)}</div>`;
      }

      badgesHtml = `${iqdBadge}${usdBadge}`;
    }

    return `
      <div class="person-card" onclick="openPersonDetails(${person.id})">
        <div class="person-card-top">
          <div class="avatar">${initial}</div>
          <div class="person-info">
            <h4>${escapeHtml(person.name)}</h4>
            <div class="phone-sub">
              ${person.phone ? `<span>📞 ${escapeHtml(person.phone)}</span>` : `<span>${bal.txCount} حركات مسجلة</span>`}
            </div>
          </div>
          <div class="arrow-icon">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="15 18 9 12 15 6"></polyline></svg>
          </div>
        </div>
        <div class="card-divider"></div>
        <div class="card-balances-row">
          ${badgesHtml}
        </div>
      </div>
    `;
  }).join('');
}

// =============================================================================
// تفاصيل الشخص وسجل الحركات
// =============================================================================
function openPersonDetails(personId) {
  activePersonId = personId;
  const person = appState.persons.find(p => p.id === personId);
  if (!person) return;

  const bal = calculatePersonBalances(personId);
  document.getElementById('detailsPersonName').textContent = person.name;

  const phoneEl = document.getElementById('detailsPersonPhone');
  if (person.phone) {
    phoneEl.innerHTML = `<a href="tel:${person.phone}" style="color: var(--primary-light); text-decoration: none;">📞 ${escapeHtml(person.phone)} (اتصال)</a>`;
  } else {
    phoneEl.textContent = person.notes || "لا يوجد رقم هاتف";
  }

  // الرصيد
  const netIqdEl = document.getElementById('detailsNetIqd');
  netIqdEl.textContent = formatIqd(bal.netIqd);
  netIqdEl.style.color = bal.netIqd > 0 ? 'var(--green-for-me)' : bal.netIqd < 0 ? 'var(--red-on-me)' : '#FFF';
  document.getElementById('detailsStatusIqd').textContent = bal.netIqd > 0 ? 'مستحق لي' : bal.netIqd < 0 ? 'مطلوب مني' : 'خالص الذمة';

  const netUsdEl = document.getElementById('detailsNetUsd');
  netUsdEl.textContent = formatUsd(bal.netUsd);
  netUsdEl.style.color = bal.netUsd > 0 ? 'var(--green-for-me)' : bal.netUsd < 0 ? 'var(--red-on-me)' : '#FFF';
  document.getElementById('detailsStatusUsd').textContent = bal.netUsd > 0 ? 'مستحق لي' : bal.netUsd < 0 ? 'مطلوب مني' : 'خالص الذمة';

  renderPersonTransactions(personId);
  openModal('modalPersonDetails');
}

function renderPersonTransactions(personId) {
  const txs = appState.transactions
    .filter(t => t.personId === personId)
    .sort((a, b) => new Date(b.date) - new Date(a.date) || b.id - a.id);

  document.getElementById('detailsTxCount').textContent = txs.length;
  const listEl = document.getElementById('detailsTxList');

  if (txs.length === 0) {
    listEl.innerHTML = `
      <div style="text-align: center; padding: 24px; color: var(--text-secondary); font-size: 13px;">
        لا توجد حركات مالية مسجلة لهذا الحساب حتى الآن.
      </div>
    `;
    return;
  }

  listEl.innerHTML = txs.map(t => {
    const isForMe = t.type === 'for_me';
    const sign = isForMe ? '+' : '-';
    const colorClass = isForMe ? 'stat-green' : 'stat-red';
    const iconClass = isForMe ? 'tx-icon-for-me' : 'tx-icon-on-me';
    const iconSymbol = isForMe ? '↓' : '↑';
    const formattedAmount = t.currency === 'IQD' ? formatIqd(t.amount) : formatUsd(t.amount);

    return `
      <div class="tx-item">
        <div class="tx-icon ${iconClass}">${iconSymbol}</div>
        <div class="tx-details">
          <div class="tx-type-line">
            <span class="${colorClass}">${isForMe ? 'دين لي (مستحق)' : 'دين علي (مطلوب)'}</span>
            <small style="background: rgba(255,255,255,0.1); padding: 1px 6px; border-radius: 6px;">${t.currency}</small>
          </div>
          ${t.notes ? `<div class="tx-note">${escapeHtml(t.notes)}</div>` : ''}
          <div class="tx-date">📅 ${t.date}</div>
        </div>
        <div class="tx-amount-side">
          <div class="tx-amount ${colorClass}">${sign}${formattedAmount}</div>
          <button class="tx-delete-btn" onclick="deleteTransaction(${t.id})" title="حذف الحركة">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6"></path></svg>
          </button>
        </div>
      </div>
    `;
  }).join('');
}

// =============================================================================
// عمليات الحركات المالية والأشخاص
// =============================================================================
function deleteTransaction(txId) {
  if (!confirm("هل أنت متأكد من حذف هذه الحركة المالية؟")) return;
  appState.transactions = appState.transactions.filter(t => t.id !== txId);
  DebtDatabase.save(appState);
  renderDashboard();
  if (activePersonId) {
    openPersonDetails(activePersonId);
  }
  showToast("تم حذف الحركة المالية", "success");
}

function openAddTransaction(type = 'for_me') {
  document.getElementById('txPersonId').value = activePersonId;
  document.getElementById('txEditId').value = '';
  document.getElementById('txAmountInput').value = '';
  document.getElementById('txNotesInput').value = '';
  document.getElementById('txDateInput').value = new Date().toISOString().split('T')[0];

  // ضبط نوع الحركة
  setTypeSegment(type);
  setCurrencySegment('IQD');

  openModal('modalTransaction');
}

function setTypeSegment(type) {
  const btnForMe = document.getElementById('btnTypeForMe');
  const btnOnMe = document.getElementById('btnTypeOnMe');
  if (type === 'for_me') {
    btnForMe.className = 'seg-btn active-green';
    btnOnMe.className = 'seg-btn';
  } else {
    btnForMe.className = 'seg-btn';
    btnOnMe.className = 'seg-btn active-red';
  }
}

function setCurrencySegment(curr) {
  const btnIqd = document.getElementById('btnCurrIqd');
  const btnUsd = document.getElementById('btnCurrUsd');
  if (curr === 'IQD') {
    btnIqd.className = 'seg-btn active-currency';
    btnUsd.className = 'seg-btn';
  } else {
    btnIqd.className = 'seg-btn';
    btnUsd.className = 'seg-btn active-currency';
  }
}

// =============================================================================
// التقارير والرسوم البيانية بواسطة Canvas
// =============================================================================
function renderReports() {
  const totals = calculateGlobalTotals();
  const totalPersons = appState.persons.length;

  let settledCount = 0;
  appState.persons.forEach(p => {
    const b = calculatePersonBalances(p.id);
    if (b.isSettled) settledCount++;
  });

  document.getElementById('rTotalPersons').textContent = totalPersons;
  document.getElementById('rActivePersons').textContent = totalPersons - settledCount;
  document.getElementById('rSettledPersons').textContent = settledCount;

  // رسم دائرة الدينار
  drawDonutChart('canvasIqdChart', totals.forMeIqd, totals.onMeIqd, 'د.ع');
  document.getElementById('chartIqdLegend').innerHTML = `
    <div class="legend-item"><span class="legend-dot" style="background: var(--green-for-me);"></span> لي: ${formatIqd(totals.forMeIqd)}</div>
    <div class="legend-item"><span class="legend-dot" style="background: var(--red-on-me);"></span> علي: ${formatIqd(totals.onMeIqd)}</div>
  `;

  // رسم دائرة الدولار
  drawDonutChart('canvasUsdChart', totals.forMeUsd, totals.onMeUsd, '$');
  document.getElementById('chartUsdLegend').innerHTML = `
    <div class="legend-item"><span class="legend-dot" style="background: var(--green-for-me);"></span> لي: ${formatUsd(totals.forMeUsd)}</div>
    <div class="legend-item"><span class="legend-dot" style="background: var(--red-on-me);"></span> علي: ${formatUsd(totals.onMeUsd)}</div>
  `;
}

function drawDonutChart(canvasId, forMe, onMe, unit) {
  const canvas = document.getElementById(canvasId);
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  const total = forMe + onMe;

  ctx.clearRect(0, 0, canvas.width, canvas.height);
  const centerX = canvas.width / 2;
  const centerY = canvas.height / 2;
  const radius = 80;
  const lineWidth = 24;

  if (total === 0) {
    ctx.beginPath();
    ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
    ctx.strokeStyle = '#334155';
    ctx.lineWidth = lineWidth;
    ctx.stroke();

    ctx.fillStyle = '#94A3B8';
    ctx.font = '14px Cairo';
    ctx.textAlign = 'center';
    ctx.fillText('لا توجد ديون', centerX, centerY + 5);
    return;
  }

  const forMeAngle = (forMe / total) * 2 * Math.PI;

  // دين لي (أخضر)
  if (forMe > 0) {
    ctx.beginPath();
    ctx.arc(centerX, centerY, radius, -Math.PI / 2, -Math.PI / 2 + forMeAngle);
    ctx.strokeStyle = '#10B981';
    ctx.lineWidth = lineWidth;
    ctx.stroke();
  }

  // دين علي (أحمر)
  if (onMe > 0) {
    ctx.beginPath();
    ctx.arc(centerX, centerY, radius, -Math.PI / 2 + forMeAngle, 1.5 * Math.PI);
    ctx.strokeStyle = '#F43F5E';
    ctx.lineWidth = lineWidth;
    ctx.stroke();
  }

  // نص في المنتصف
  ctx.fillStyle = '#FFFFFF';
  ctx.font = 'bold 15px Cairo';
  ctx.textAlign = 'center';
  ctx.fillText(`${formatNumber(total)} ${unit}`, centerX, centerY + 5);
}

// =============================================================================
// النسخ الاحتياطي والاسترجاع
// =============================================================================
function exportBackup() {
  const dataStr = JSON.stringify(appState, null, 2);
  const fileName = `zied_debts_backup_${new Date().toISOString().slice(0,10)}.json`;

  // دعم Web Share API لنظام iOS Safari
  if (navigator.share && navigator.canShare && navigator.canShare({ files: [new File([dataStr], fileName, { type: 'application/json' })] })) {
    const file = new File([dataStr], fileName, { type: 'application/json' });
    navigator.share({
      title: 'نسخة احتياطية لتطبيق زيد اياد للديون',
      files: [file]
    }).catch(() => downloadFile(dataStr, fileName));
  } else {
    downloadFile(dataStr, fileName);
  }
}

function downloadFile(content, fileName) {
  const blob = new Blob([content], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = fileName;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
  showToast("تم تنزيل ملف النسخة الاحتياطية بنجاح", "success");
}

function importBackup(file) {
  const reader = new FileReader();
  reader.onload = (e) => {
    try {
      const data = JSON.parse(e.target.result);
      if (Array.isArray(data.persons) && Array.isArray(data.transactions)) {
        if (confirm(`هل أنت متأكد من استرجاع النسخة؟\nسيتم استبدال البيانات الحالية بـ (${data.persons.length}) أشخاص و (${data.transactions.length}) حركة.`)) {
          appState = data;
          DebtDatabase.save(appState);
          renderDashboard();
          closeModal('modalSettings');
          showToast("تم استرجاع البيانات بنجاح!", "success");
        }
      } else {
        alert("ملف غير صالح. يرجى اختيار ملف JSON تم تصديره من هذا التطبيق.");
      }
    } catch (err) {
      alert("حدث خطأ أثناء قراءة الملف.");
    }
  };
  reader.readAsText(file);
}

// =============================================================================
// مساعدات النوافذ المنبثقة والتنبيهات
// =============================================================================
function openModal(id) {
  document.getElementById(id).classList.add('active');
}

function closeModal(id) {
  document.getElementById(id).classList.remove('active');
}

function showToast(msg, type = 'info') {
  const container = document.getElementById('toastContainer');
  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.textContent = msg;
  container.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = '0';
    setTimeout(() => toast.remove(), 300);
  }, 2500);
}

function escapeHtml(str) {
  if (!str) return '';
  return str.replace(/[&<>"']/g, m => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#39;'
  }[m]));
}

// =============================================================================
// ربط الأحداث (Event Listeners)
// =============================================================================
document.addEventListener('DOMContentLoaded', () => {
  renderDashboard();

  // فحص تثبيت الآيفون
  const isIos = /iphone|ipad|ipod/.test(window.navigator.userAgent.toLowerCase());
  const isStandalone = window.navigator.standalone === true || window.matchMedia('(display-mode: standalone)').matches;
  if (isIos && !isStandalone) {
    document.getElementById('iosInstallBanner').style.display = 'flex';
  }
  document.getElementById('dismissIosBanner').addEventListener('click', () => {
    document.getElementById('iosInstallBanner').style.display = 'none';
  });

  // فتح وإغلاق النوافذ
  document.querySelectorAll('[data-close]').forEach(btn => {
    btn.addEventListener('click', () => closeModal(btn.getAttribute('data-close')));
  });

  document.querySelectorAll('.modal-overlay').forEach(overlay => {
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) closeModal(overlay.id);
    });
  });

  // أزرار الهيدر
  document.getElementById('btnReports').addEventListener('click', () => {
    renderReports();
    openModal('modalReports');
  });

  document.getElementById('btnSettings').addEventListener('click', () => {
    openModal('modalSettings');
  });

  document.getElementById('heroRatePill').addEventListener('click', () => {
    openModal('modalSettings');
  });

  // البحث
  const searchInput = document.getElementById('searchInput');
  const clearBtn = document.getElementById('clearSearch');
  searchInput.addEventListener('input', () => {
    clearBtn.style.display = searchInput.value ? 'block' : 'none';
    renderPersonsList();
  });
  clearBtn.addEventListener('click', () => {
    searchInput.value = '';
    clearBtn.style.display = 'none';
    renderPersonsList();
  });

  // الفلاتر
  document.querySelectorAll('.chip').forEach(chip => {
    chip.addEventListener('click', () => {
      document.querySelectorAll('.chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      currentFilter = chip.getAttribute('data-filter');
      renderPersonsList();
    });
  });

  // إضافة شخص
  document.getElementById('btnFloatingAddPerson').addEventListener('click', () => {
    document.getElementById('modalPersonTitle').textContent = "إضافة شخص جديد";
    document.getElementById('personEditId').value = '';
    document.getElementById('personNameInput').value = '';
    document.getElementById('personPhoneInput').value = '';
    document.getElementById('personNotesInput').value = '';
    openModal('modalPerson');
  });

  document.getElementById('formPerson').addEventListener('submit', (e) => {
    e.preventDefault();
    const editId = document.getElementById('personEditId').value;
    const name = document.getElementById('personNameInput').value.trim();
    const phone = document.getElementById('personPhoneInput').value.trim();
    const notes = document.getElementById('personNotesInput').value.trim();

    if (!name) return;

    if (editId) {
      const person = appState.persons.find(p => p.id === parseInt(editId));
      if (person) {
        person.name = name;
        person.phone = phone;
        person.notes = notes;
      }
      showToast("تم تعديل بيانات الشخص", "success");
    } else {
      const newPerson = {
        id: Date.now(),
        name,
        phone,
        notes,
        createdAt: new Date().toISOString()
      };
      appState.persons.unshift(newPerson);
      showToast("تمت إضافة الشخص بنجاح", "success");
    }

    DebtDatabase.save(appState);
    renderDashboard();
    closeModal('modalPerson');
    if (activePersonId && editId) {
      openPersonDetails(activePersonId);
    }
  });

  // تعديل الشخص من شاشة التفاصيل
  document.getElementById('btnEditPersonFromDetails').addEventListener('click', () => {
    const person = appState.persons.find(p => p.id === activePersonId);
    if (!person) return;
    document.getElementById('modalPersonTitle').textContent = "تعديل بيانات الشخص";
    document.getElementById('personEditId').value = person.id;
    document.getElementById('personNameInput').value = person.name;
    document.getElementById('personPhoneInput').value = person.phone || '';
    document.getElementById('personNotesInput').value = person.notes || '';
    openModal('modalPerson');
  });

  // حذف الشخص من شاشة التفاصيل
  document.getElementById('btnDeletePersonFromDetails').addEventListener('click', () => {
    if (!confirm("هل أنت متأكد من حذف هذا الشخص؟ سيتم حذف جميع الحركات المالية المرتبطة به بشكل نهائي.")) return;
    appState.persons = appState.persons.filter(p => p.id !== activePersonId);
    appState.transactions = appState.transactions.filter(t => t.personId !== activePersonId);
    DebtDatabase.save(appState);
    closeModal('modalPersonDetails');
    renderDashboard();
    showToast("تم حذف الشخص وسجلاته", "success");
  });

  // أزرار التسجيل السريع
  document.getElementById('btnQuickDebtForMe').addEventListener('click', () => openAddTransaction('for_me'));
  document.getElementById('btnQuickDebtOnMe').addEventListener('click', () => openAddTransaction('on_me'));

  // محددات الحركة
  document.getElementById('btnTypeForMe').addEventListener('click', () => setTypeSegment('for_me'));
  document.getElementById('btnTypeOnMe').addEventListener('click', () => setTypeSegment('on_me'));
  document.getElementById('btnCurrIqd').addEventListener('click', () => setCurrencySegment('IQD'));
  document.getElementById('btnCurrUsd').addEventListener('click', () => setCurrencySegment('USD'));

  // حفظ الحركة
  document.getElementById('formTransaction').addEventListener('submit', (e) => {
    e.preventDefault();
    const personId = parseInt(document.getElementById('txPersonId').value);
    const amount = parseFloat(document.getElementById('txAmountInput').value);
    const date = document.getElementById('txDateInput').value;
    const notes = document.getElementById('txNotesInput').value.trim();
    const type = document.getElementById('btnTypeForMe').classList.contains('active-green') ? 'for_me' : 'on_me';
    const currency = document.getElementById('btnCurrIqd').classList.contains('active-currency') ? 'IQD' : 'USD';

    if (!amount || amount <= 0) {
      alert("يرجى إدخال مبلغ صحيح أكبر من الصفر");
      return;
    }

    const newTx = {
      id: Date.now(),
      personId,
      type,
      amount,
      currency,
      date,
      notes
    };

    appState.transactions.unshift(newTx);
    DebtDatabase.save(appState);
    renderDashboard();
    closeModal('modalTransaction');
    if (activePersonId) {
      openPersonDetails(activePersonId);
    }
    showToast("تمت إضافة الحركة بنجاح", "success");
  });

  // تحديث سعر الصرف
  document.getElementById('btnSaveRate').addEventListener('click', () => {
    const rate = parseFloat(document.getElementById('settingRateInput').value);
    if (rate && rate > 0) {
      appState.exchangeRate = rate;
      DebtDatabase.save(appState);
      renderDashboard();
      showToast("تم تحديث سعر الصرف", "success");
    }
  });

  // النسخ والاسترجاع
  document.getElementById('btnExportBackup').addEventListener('click', exportBackup);
  document.getElementById('importFileInput').addEventListener('change', (e) => {
    if (e.target.files.length > 0) {
      importBackup(e.target.files[0]);
    }
  });

  // مسح وتصفير البيانات
  document.getElementById('btnClearAllData').addEventListener('click', () => {
    if (confirm("هل أنت متأكد من مسح كافة البيانات وتصفير التطبيق؟")) {
      appState = DebtDatabase.clear();
      renderDashboard();
      closeModal('modalSettings');
      showToast("تم مسح كافة البيانات", "error");
    }
  });

  // زرع البيانات التجريبية
  document.getElementById('btnSeedDemoData').addEventListener('click', () => {
    appState = DebtDatabase.reset();
    renderDashboard();
    closeModal('modalSettings');
    showToast("تمت استعادة البيانات التجريبية", "success");
  });
});
