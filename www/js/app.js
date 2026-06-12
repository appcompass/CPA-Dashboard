const WHEEL_DEFAULT_MESSAGE = 'Select a segment to learn more.';

const WHEEL_META = [
  {
    key: 'physical',
    canonicalTitle: 'Physical',
    color: '#066fd1',
    titleKey: 'wellness_physical',
    descriptionKey: 'desc_physical',
    subKeys: [
      'wellness_physical_fitness',
      'wellness_physical_nutrition',
      'wellness_physical_screenings',
      'wellness_physical_other',
    ],
  },
  {
    key: 'emotional',
    canonicalTitle: 'Emotional',
    color: '#4299e1',
    titleKey: 'wellness_emotional',
    descriptionKey: 'desc_emotional',
    subKeys: [
      'sub_emotional_1',
      'sub_emotional_2',
      'sub_emotional_3',
      'wellness_physical_other',
    ],
  },
  {
    key: 'intellectual',
    canonicalTitle: 'Intellectual',
    color: '#ae3ec9',
    titleKey: 'wellness_intellectual',
    descriptionKey: 'desc_intellectual',
    subKeys: [
      'sub_intellectual_1',
      'sub_intellectual_2',
      'sub_intellectual_3',
      'wellness_physical_other',
    ],
  },
  {
    key: 'occupational',
    canonicalTitle: 'Occupational',
    color: '#d63939',
    titleKey: 'wellness_occupational',
    descriptionKey: 'desc_occupational',
    subKeys: [
      'sub_occupational_1',
      'sub_occupational_2',
      'sub_occupational_3',
      'sub_occupational_4',
      'wellness_physical_other',
    ],
  },
  {
    key: 'financial',
    canonicalTitle: 'Financial',
    color: '#f59f00',
    titleKey: 'wellness_financial',
    descriptionKey: 'desc_financial',
    subKeys: [
      'sub_financial_1',
      'sub_financial_2',
      'sub_financial_3',
      'wellness_physical_other',
    ],
  },
  {
    key: 'social',
    canonicalTitle: 'Social',
    color: '#2fb344',
    titleKey: 'wellness_social',
    descriptionKey: 'desc_social',
    subKeys: [
      'sub_social_1',
      'sub_social_2',
      'sub_social_3',
      'wellness_physical_other',
    ],
  },
  {
    key: 'environmental',
    canonicalTitle: 'Environmental',
    color: '#0ca678',
    titleKey: 'wellness_environmental',
    descriptionKey: 'desc_environmental',
    subKeys: [
      'sub_environmental_1',
      'sub_environmental_2',
      'sub_environmental_3',
      'wellness_physical_other',
    ],
  },
  {
    key: 'spiritual',
    canonicalTitle: 'Spiritual',
    color: '#17a2b8',
    titleKey: 'wellness_spiritual',
    descriptionKey: 'desc_spiritual',
    subKeys: [
      'sub_spiritual_1',
      'sub_spiritual_2',
      'sub_spiritual_3',
      'sub_spiritual_4',
      'wellness_physical_other',
    ],
  },
];

function parseSearchParams(search) {
  const out = {};
  const raw = (search || '').replace(/^\?/, '');
  if (!raw) {
    return out;
  }

  raw.split('&').forEach(function (part) {
    if (!part) {
      return;
    }
    const bits = part.split('=');
    const key = decodeURIComponent((bits[0] || '').replace(/\+/g, ' '));
    const value = decodeURIComponent(
      (bits.slice(1).join('=') || '').replace(/\+/g, ' '),
    );
    if (key) {
      out[key] = value;
    }
  });

  return out;
}

function parseCurrentLangCode() {
  const params = parseSearchParams(window.location.search || '');
  return params.lang || 'en';
}

function getNestedValue(obj, path) {
  if (!obj || !path) {
    return undefined;
  }

  return path.split('.').reduce(function (acc, key) {
    if (acc && Object.prototype.hasOwnProperty.call(acc, key)) {
      return acc[key];
    }
    return undefined;
  }, obj);
}

function getTranslationScope() {
  const allTranslations = window.APP_TRANSLATIONS || {};
  const langCode = parseCurrentLangCode();

  const enScope = allTranslations.en || {};
  const activeScope = allTranslations[langCode] || {};

  return {
    organizations: Object.assign(
      {},
      enScope.organizations || {},
      activeScope.organizations || {},
    ),
    wheel: Object.assign({}, enScope.wheel || {}, activeScope.wheel || {}),
    theme_settings: Object.assign(
      {},
      enScope.theme_settings || {},
      activeScope.theme_settings || {},
      {
        options: Object.assign(
          {},
          (enScope.theme_settings && enScope.theme_settings.options) || {},
          (activeScope.theme_settings && activeScope.theme_settings.options) ||
            {},
        ),
      },
    ),
  };
}

function applyThemeSettingsTranslations() {
  const panel = document.getElementById('offcanvasSettings');
  if (!panel) {
    return;
  }

  const scope = getTranslationScope();
  const fallbackScope = (window.APP_TRANSLATIONS || {}).en || {};

  panel.querySelectorAll('[data-i18n]').forEach(function (node) {
    const key = node.getAttribute('data-i18n');
    if (!key) {
      return;
    }

    const translated =
      getNestedValue(scope, key) || getNestedValue(fallbackScope, key);
    if (!translated) {
      return;
    }

    const attrName = node.getAttribute('data-i18n-attr');
    if (attrName) {
      node.setAttribute(attrName, translated);
      return;
    }

    node.textContent = translated;
  });
}

function buildWheelItems() {
  const scope = getTranslationScope();
  const organizations = scope.organizations;
  const wheel = scope.wheel;

  return WHEEL_META.map(function (meta) {
    const title = organizations[meta.titleKey] || meta.canonicalTitle;
    const subs = meta.subKeys.map(function (key) {
      return organizations[key] || wheel[key] || key;
    });

    return {
      color: meta.color,
      title: title,
      desc: wheel[meta.descriptionKey] || '',
      subs: subs,
      matchTokens: [
        meta.key.toLowerCase(),
        meta.canonicalTitle.toLowerCase(),
        String(title).toLowerCase(),
      ],
    };
  });
}

const PULL = 26,
  DUR = 600;
const R_OUT = 220,
  R_IN = 105,
  CX = 250,
  CY = 250;

function createWheel(container, size = 340) {
  if (!container || container.classList.contains('ww-wheel-instance')) {
    return;
  }

  const scope = getTranslationScope();
  const ALL = buildWheelItems();

  const attrValue = container.dataset.activeCategories || '';
  const allowedTitles = attrValue
    .split(',')
    .map((s) => s.trim().toLowerCase())
    .filter(Boolean);
  const ENABLED = ALL.filter((d) =>
    d.matchTokens.some((token) => allowedTitles.includes(token)),
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
  defaultMsg.textContent = scope.wheel.default_message || WHEEL_DEFAULT_MESSAGE;
  panelsEl.appendChild(defaultMsg);

  wrap.appendChild(svgWrap);
  wrap.appendChild(panelsEl);
  container.appendChild(wrap);

  // build panels
  ENABLED.forEach((d, i) => {
    const otherLabel = scope.organizations.wellness_physical_other || 'Other';

    const div = document.createElement('div');
    div.className = 'panel';
    div.id = uid + '-panel-' + i;
    div.innerHTML = `
      <p class="panel-title" style="color:${d.color}">${d.title}</p>
      <p class="panel-desc">${d.desc}</p>
      <ul class="subcats">${d.subs
        .map(
          (s) => `<li>
        <span class="dot" style="background:${s === otherLabel ? 'var(--color-border-secondary)' : d.color}"></span>
        <span class="${s === otherLabel ? 'other' : 'subcat-name'}">${s}</span>
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

      const titleLength = String(d.title || '').length;
      var labelSize = sweep < 50 ? 9 : 10.5;
      if (titleLength > 18) {
        labelSize -= 1;
      }
      if (titleLength > 26) {
        labelSize -= 0.5;
      }

      const label = g
        .text(d.title)
        .font({
          family: 'sans-serif',
          size: Math.max(7.5, labelSize),
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

window.createWheel = createWheel;

document.addEventListener('DOMContentLoaded', function () {
  document.body.classList.add('app-ready');
  applyThemeSettingsTranslations();

  var themeConfig = {
    theme: 'light',
    'theme-base': 'gray',
    'theme-font': 'sans-serif',
    'theme-primary': 'blue',
    'theme-radius': '1',
  };
  var stringifySearch = function (params) {
    var keys = Object.keys(params).filter(function (k) {
      return params[k] !== undefined && params[k] !== null && params[k] !== '';
    });

    if (!keys.length) {
      return '';
    }

    return (
      '?' +
      keys
        .map(function (k) {
          return (
            encodeURIComponent(k) + '=' + encodeURIComponent(String(params[k]))
          );
        })
        .join('&')
    );
  };

  var queryParams = parseSearchParams(window.location.search);
  var mergeCurrentSearchIntoRouterHref = function (href) {
    if (!href) {
      return href;
    }

    var hashIndex = href.indexOf('#!/');
    if (hashIndex < 0) {
      return href;
    }

    var queryIndex = href.indexOf('?');
    var hasQueryBeforeHash = queryIndex >= 0 && queryIndex < hashIndex;
    if (hasQueryBeforeHash) {
      return href;
    }

    var currentSearch = window.location.search || '';
    if (!currentSearch) {
      return href;
    }

    return href.slice(0, hashIndex) + currentSearch + href.slice(hashIndex);
  };

  var syncRouterLinksWithQueryParams = function () {
    document.querySelectorAll('a[href*="#!/"]').forEach(function (anchor) {
      var href = anchor.getAttribute('href');
      var mergedHref = mergeCurrentSearchIntoRouterHref(href);
      if (mergedHref && mergedHref !== href) {
        anchor.setAttribute('href', mergedHref);
      }
    });
  };

  var refreshQueryParams = function () {
    queryParams = parseSearchParams(window.location.search);
    syncRouterLinksWithQueryParams();
    return queryParams;
  };
  var getParam = function (key) {
    return queryParams[key];
  };
  var setParam = function (key, value) {
    queryParams[key] = value;
  };
  var deleteParam = function (key) {
    delete queryParams[key];
  };
  var pushQuery = function () {
    var nextUrl =
      window.location.pathname +
      stringifySearch(queryParams) +
      window.location.hash;
    window.history.pushState({}, '', nextUrl);
  };

  var form = document.getElementById('offcanvasSettings');
  var resetButton = document.getElementById('reset-changes');
  var checkItems = function () {
    if (!form) {
      return;
    }

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
  if (form) {
    form.addEventListener('change', function (event) {
      refreshQueryParams();
      var target = event.target,
        name = target.name,
        value = target.value;
      for (var key in themeConfig) {
        if (name === key) {
          document.documentElement.setAttribute('data-bs-' + key, value);
          window.localStorage.setItem('tabler-' + key, value);
          setParam(key, value);
        }
      }
      pushQuery();
    });
  }

  if (resetButton) {
    resetButton.addEventListener('click', function () {
      refreshQueryParams();
      for (var key in themeConfig) {
        var value = themeConfig[key];
        document.documentElement.removeAttribute('data-bs-' + key);
        window.localStorage.removeItem('tabler-' + key);
        deleteParam(key);
      }
      checkItems();
      pushQuery();
    });
  }

  checkItems();
  syncRouterLinksWithQueryParams();

  document.addEventListener('click', function (event) {
    var anchor = event.target.closest('a[href]');
    if (!anchor) {
      return;
    }

    var href = anchor.getAttribute('href');
    var mergedHref = mergeCurrentSearchIntoRouterHref(href);
    if (mergedHref && mergedHref !== href) {
      event.preventDefault();
      window.location.assign(mergedHref);
    }
  });

  var initWheels = function () {
    document
      .querySelectorAll('[data-active-categories]')
      .forEach(function (container) {
        createWheel(container, 440);
      });
  };

  var initWheelsNowAndNextTick = function () {
    applyThemeSettingsTranslations();
    initWheels();
    window.setTimeout(initWheels, 0);
  };

  initWheelsNowAndNextTick();

  // Shiny/router render content after DOMContentLoaded, so re-run wheel setup
  // when outputs update, hash navigation changes, or DOM nodes are injected.
  document.addEventListener('shiny:value', initWheelsNowAndNextTick);
  window.addEventListener('hashchange', initWheelsNowAndNextTick);

  if (window.MutationObserver) {
    var wheelObserver = new MutationObserver(function () {
      initWheels();
    });

    wheelObserver.observe(document.body, {
      childList: true,
      subtree: true,
    });
  }

  var wheelInitAttempts = 0;
  var wheelInitTimer = window.setInterval(function () {
    initWheels();
    wheelInitAttempts += 1;

    var total = document.querySelectorAll('[data-active-categories]').length;
    var initialized = document.querySelectorAll(
      '[data-active-categories].ww-wheel-instance',
    ).length;

    if ((total > 0 && total === initialized) || wheelInitAttempts >= 20) {
      window.clearInterval(wheelInitTimer);
    }
  }, 300);
});
