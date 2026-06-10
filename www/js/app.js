const ALL = [
  {
    color: '#066fd1',
    title: 'Physical',
    desc: 'Physical wellness is the ability to recognize the need for physical activity, healthy diet, sleep and nutrition. Examples include after-school sport clubs, summer exercise camps, community gardens, cooking classes, and information about well-being.',
    subs: [
      'Fitness programs',
      'Nutritional education',
      'Health screenings',
      'Other',
    ],
  },
  {
    color: '#4299e1',
    title: 'Emotional',
    desc: 'Emotional wellness is the ability to cope effectively with life and create satisfying relationships, including obtaining high-quality mental health treatment and support as needed. Examples include trauma-informed programming, therapy services, and mentoring programs aimed at supporting socioemotional learning.',
    subs: [
      'Mental health support groups',
      'Crisis intervention',
      'Counseling services',
      'Other',
    ],
  },
  {
    color: '#ae3ec9',
    title: 'Intellectual',
    desc: 'Intellectual wellness is the ability to recognize creative abilities and find ways to expand knowledge and skills. Examples include art classes, tutoring, creative writing, SAT prep, and coding workshops.',
    subs: [
      'Educational workshops',
      'College readiness programs',
      'Tutoring',
      'Other',
    ],
  },
  {
    color: '#d63939',
    title: 'Occupational',
    desc: "Occupational wellness is defined as having personal satisfaction and enrichment from one's work. Examples include resources for resume development, job fairs, and career counseling.",
    subs: [
      'Internships / co-ops',
      'Career counseling',
      'Resume support',
      'Job training',
      'Other',
    ],
  },
  {
    color: '#f59f00',
    title: 'Financial',
    desc: "Financial wellness is one's satisfaction with current and future financial situations. Examples include initiatives centered on managing finances, financial aid, and increasing financial literacy.",
    subs: [
      'Budgeting',
      'Assistance with financial aid',
      'Financial literacy workshops',
      'Other',
    ],
  },
  {
    color: '#2fb344',
    title: 'Social',
    desc: 'Social wellness is the ability to develop a sense of connection, belonging and a well-developed support system. Examples include hosting social events, camps or opportunities to engage with sports teams between community peers, and support groups of same-age peers.',
    subs: [
      'Mentoring',
      'Family engagement activities',
      'Community events',
      'Other',
    ],
  },
  {
    color: '#0ca678',
    title: 'Environmental',
    desc: 'Environmental wellness is having good health by occupying pleasant, stimulating environments that support wellbeing. Examples include access to parks and safe walking space, living in a neighborhood where youth feel safe, and engaging in climate change initiatives.',
    subs: [
      'Environmental education',
      'Neighborhood clean-ups',
      'Community gardening',
      'Other',
    ],
  },
  {
    color: '#17a2b8',
    title: 'Spiritual',
    desc: 'Spiritual wellness is expanding our sense of purpose and meaning in life. Examples include meditation, attending religious events, and providing designated areas of spiritual practice.',
    subs: [
      'Mindfulness or meditation workshops',
      'Religious support groups / counseling',
      'Physical space for religious practices',
      'Religious or spiritual themed events',
      'Other',
    ],
  },
];

const PULL = 26,
  DUR = 600;
const R_OUT = 220,
  R_IN = 105,
  CX = 250,
  CY = 250;

function createWheel(container, size = 340) {
  const attrValue = container.dataset.activeCategories || '';
  const allowedTitles = attrValue
    .split(',')
    .map((s) => s.trim().toLowerCase())
    .filter(Boolean);
  const ENABLED = ALL.filter((d) =>
    allowedTitles.includes(d.title.toLowerCase()),
  );
  if (!ENABLED.length) return;

  // unique id prefix per instance
  const uid = 'ww-' + Math.random().toString(36).slice(2, 7);

  container.classList.add('ww-wheel-instance');

  const wrap = document.createElement('div');
  wrap.className = 'ww-wrap';

  const svgWrap = document.createElement('div');
  svgWrap.style.cssText = `flex-shrink:0;width:${size}px;height:${size}px;overflow:visible`;

  const panelsEl = document.createElement('div');
  panelsEl.style.cssText = 'flex:1;min-width:0;position:relative';

  const defaultMsg = document.createElement('div');
  defaultMsg.className = 'default-msg';
  defaultMsg.textContent = 'Select a segment to learn more.';
  panelsEl.appendChild(defaultMsg);

  wrap.appendChild(svgWrap);
  wrap.appendChild(panelsEl);
  container.appendChild(wrap);

  // build panels
  ENABLED.forEach((d, i) => {
    const div = document.createElement('div');
    div.className = 'panel';
    div.id = uid + '-panel-' + i;
    div.innerHTML = `
      <p class="panel-title" style="color:${d.color}">${d.title}</p>
      <p class="panel-desc">${d.desc}</p>
      <ul class="subcats">${d.subs
        .map(
          (s) => `<li>
        <span class="dot" style="background:${s === 'Other' ? 'var(--color-border-secondary)' : d.color}"></span>
        <span class="${s === 'Other' ? 'other' : 'subcat-name'}">${s}</span>
      </li>`,
        )
        .join('')}</ul>`;
    panelsEl.appendChild(div);
  });

  // SVG.js instance
  const draw = SVG()
    .addTo(svgWrap)
    .viewbox(0, 0, 500, 500)
    .size(size, size)
    .attr('overflow', 'visible');
  const wheelGroup = draw.group();

  let activeSegIdx = -1;
  let currentRotation = 0;
  let segMap = {};

  function toRad(deg) {
    return (deg * Math.PI) / 180;
  }
  function polarPt(r, deg) {
    return {
      x: CX + r * Math.cos(toRad(deg)),
      y: CY + r * Math.sin(toRad(deg)),
    };
  }
  function arcPath(startDeg, endDeg) {
    const o1 = polarPt(R_OUT, startDeg),
      o2 = polarPt(R_OUT, endDeg);
    const i2 = polarPt(R_IN, endDeg),
      i1 = polarPt(R_IN, startDeg);
    const lg = endDeg - startDeg > 180 ? 1 : 0;
    const f = (n) => +n.toFixed(4);
    return `M ${f(o1.x)},${f(o1.y)} A ${R_OUT},${R_OUT} 0 ${lg},1 ${f(o2.x)},${f(o2.y)} L ${f(i2.x)},${f(i2.y)} A ${R_IN},${R_IN} 0 ${lg},0 ${f(i1.x)},${f(i1.y)} Z`;
  }
  function fullRingPath() {
    return arcPath(-90, 269.999);
  }

  function showPanel(idx) {
    panelsEl
      .querySelectorAll('.panel')
      .forEach((p) => p.classList.remove('visible'));
    if (idx >= 0) {
      defaultMsg.style.display = 'none';
      const p = document.getElementById(uid + '-panel-' + idx);
      if (p) p.classList.add('visible');
    } else {
      defaultMsg.style.display = 'block';
    }
  }

  function applyState() {
    wheelGroup
      .animate(DUR, '<>')
      .transform({ rotate: currentRotation, ox: CX, oy: CY });
    Object.entries(segMap).forEach(([i, s]) => {
      const idx = parseInt(i);
      s.label
        .animate(DUR, '<>')
        .transform({ rotate: -currentRotation, ox: s.lp.x, oy: s.lp.y });
      if (idx === activeSegIdx) {
        const rad = toRad(s.midDeg);
        s.tx = Math.cos(rad) * PULL;
        s.ty = Math.sin(rad) * PULL;
      } else {
        s.tx = 0;
        s.ty = 0;
      }
      s.group.animate(DUR, '<>').transform({ translate: [s.tx, s.ty] });
    });
    showPanel(activeSegIdx);
  }

  function render() {
    Object.values(segMap).forEach((s) => s.group.remove());
    segMap = {};
    activeSegIdx = -1;
    currentRotation = 0;
    wheelGroup.transform({ rotate: 0, ox: CX, oy: CY });

    const n = ENABLED.length;
    if (!n) {
      showPanel(-1);
      return;
    }

    if (n === 1) {
      const d = ENABLED[0];
      activeSegIdx = 0;
      const g = wheelGroup.group();
      g.path(fullRingPath()).fill(d.color).stroke({ color: 'white', width: 2 });
      g.text(d.title)
        .font({
          family: 'sans-serif',
          size: 16,
          weight: '600',
          anchor: 'middle',
        })
        .fill('white')
        .center(CX, CY);
      segMap[0] = {
        group: g,
        label: g.last(),
        midDeg: 0,
        lp: { x: CX, y: CY },
        tx: 0,
        ty: 0,
      };
      showPanel(0);
      return;
    }

    const sweep = 360 / n;
    ENABLED.forEach((d, i) => {
      const startDeg = -90 + i * sweep;
      const endDeg = startDeg + sweep;
      const midDeg = startDeg + sweep / 2;
      const lp = polarPt((R_OUT + R_IN) / 2 + 4, midDeg);

      const g = wheelGroup.group().attr('cursor', 'pointer');
      g.path(arcPath(startDeg, endDeg))
        .fill(d.color)
        .stroke({ color: 'white', width: 2 });

      const label = g
        .text(d.title)
        .font({
          family: 'sans-serif',
          size: sweep < 50 ? 10.5 : 12,
          weight: '600',
          anchor: 'middle',
        })
        .fill('white')
        .center(lp.x, lp.y);

      segMap[i] = { group: g, label, midDeg, lp, tx: 0, ty: 0 };

      g.click(() => {
        const wasActive = activeSegIdx === i;
        activeSegIdx = wasActive ? -1 : i;
        if (wasActive) {
          let delta = ((((0 - currentRotation) % 360) + 540) % 360) - 180;
          currentRotation += delta;
        } else {
          const target = -midDeg;
          let delta = ((((target - currentRotation) % 360) + 540) % 360) - 180;
          currentRotation += delta;
        }
        applyState();
      });
    });

    applyState();
  }

  render();
}

document.addEventListener('DOMContentLoaded', function () {
  document.body.classList.add('app-ready');
  var themeConfig = {
    theme: 'light',
    'theme-base': 'gray',
    'theme-font': 'sans-serif',
    'theme-primary': 'blue',
    'theme-radius': '1',
  };
  var url = new URL(window.location);
  var form = document.getElementById('offcanvasSettings');
  var resetButton = document.getElementById('reset-changes');
  var checkItems = function () {
    for (var key in themeConfig) {
      var value = window.localStorage['tabler-' + key] || themeConfig[key];
      if (!!value) {
        var radios = form.querySelectorAll(`[name="${key}"]`);
        if (!!radios) {
          radios.forEach((radio) => {
            radio.checked = radio.value === value;
          });
        }
      }
    }
  };
  form.addEventListener('change', function (event) {
    var target = event.target,
      name = target.name,
      value = target.value;
    for (var key in themeConfig) {
      if (name === key) {
        document.documentElement.setAttribute('data-bs-' + key, value);
        window.localStorage.setItem('tabler-' + key, value);
        url.searchParams.set(key, value);
      }
    }
    window.history.pushState({}, '', url);
  });
  resetButton.addEventListener('click', function () {
    for (var key in themeConfig) {
      var value = themeConfig[key];
      document.documentElement.removeAttribute('data-bs-' + key);
      window.localStorage.removeItem('tabler-' + key);
      url.searchParams.delete(key);
    }
    checkItems();
    window.history.pushState({}, '', url);
  });
  checkItems();
  document
    .querySelectorAll('[data-active-categories]')
    .forEach((container) => createWheel(container, 340));
});
