// Client-side behavior for the dashboard, built on the jQuery that Shiny loads:
// the interactive wellness wheel (SVG.js), live organizations filtering, theme
// settings, language-aware router links, and the initial page fade-in. Reads
// translations from window.APP_TRANSLATIONS (injected by main_ui.R).

const WHEEL_DEFAULT_MESSAGE = 'Select a segment to learn more.';

// Wellness dimensions: color, icon, and the translation keys for the title,
// description, and sub-categories that populate each wheel segment and panel.
const WHEEL_META = [
  {
    key: 'physical',
    canonicalTitle: 'Physical',
    color: '#066fd1',
    icon: `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-tabler icons-tabler-outline icon-tabler-heartbeat"><path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M19.5 13.572l-7.5 7.428l-2.896 -2.868m-6.117 -8.104a5 5 0 0 1 9.013 -3.022a5 5 0 1 1 7.5 6.572" /><path d="M3 13h2l2 3l2 -6l1 3h3" /></svg>`,
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
    icon: `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-tabler icons-tabler-outline icon-tabler-user-heart"><path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M8 7a4 4 0 1 0 8 0a4 4 0 0 0 -8 0" /><path d="M6 21v-2a4 4 0 0 1 4 -4h.5" /><path d="M18 22l3.35 -3.284a2.143 2.143 0 0 0 .005 -3.071a2.242 2.242 0 0 0 -3.129 -.006l-.224 .22l-.223 -.22a2.242 2.242 0 0 0 -3.128 -.006a2.143 2.143 0 0 0 -.006 3.071l3.355 3.296" /></svg>`,
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
    icon: `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-tabler icons-tabler-outline icon-tabler-school"><path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M22 9l-10 -4l-10 4l10 4l10 -4v6" /><path d="M6 10.6v5.4a6 3 0 0 0 12 0v-5.4" /></svg>`,
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
    icon: `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-tabler icons-tabler-outline icon-tabler-briefcase-2"><path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M3 9a2 2 0 0 1 2 -2h14a2 2 0 0 1 2 2v9a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2v-9" /><path d="M8 7v-2a2 2 0 0 1 2 -2h4a2 2 0 0 1 2 2v2" /></svg>`,
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
    icon: `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-tabler icons-tabler-outline icon-tabler-report-money"><path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M9 5h-2a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-12a2 2 0 0 0 -2 -2h-2" /><path d="M9 5a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2a2 2 0 0 1 -2 2h-2a2 2 0 0 1 -2 -2" /><path d="M14 11h-2.5a1.5 1.5 0 0 0 0 3h1a1.5 1.5 0 0 1 0 3h-2.5" /><path d="M12 17v1m0 -8v1" /></svg>`,
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
    icon: `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-tabler icons-tabler-outline icon-tabler-friends"><path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M5 5a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" /><path d="M5 22v-5l-1 -1v-4a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v4l-1 1v5" /><path d="M15 5a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" /><path d="M15 22v-4h-2l2 -6a1 1 0 0 1 1 -1h2a1 1 0 0 1 1 1l2 6h-2v4" /></svg>`,
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
    icon: `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-tabler icons-tabler-outline icon-tabler-world-map"><path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M20 8h-2a2 2 0 0 0 -2 2a2 2 0 1 1 -4 0v-1a2 2 0 0 0 -2 -2h-1a2 2 0 0 1 -2 -2v-.5" /><path d="M3 12h3a2 2 0 0 1 2 2v.5a1.5 1.5 0 0 0 1.5 1.5a1.5 1.5 0 0 1 1.5 1.5v3.25" /><path d="M15 20.5v-3.5a2 2 0 0 1 2 -2h3.5" /><path d="M3 12a9 9 0 1 0 18 0a9 9 0 1 0 -18 0" /></svg>`,
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
    icon: `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-tabler icons-tabler-outline icon-tabler-peace"><path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M3 12a9 9 0 1 0 18 0a9 9 0 1 0 -18 0" /><path d="M12 3l0 18" /><path d="M12 12l6.3 6.3" /><path d="M12 12l-6.3 6.3" /></svg>`,
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
  const $panel = $('#offcanvasSettings');
  if (!$panel.length) {
    return;
  }

  const scope = getTranslationScope();
  const fallbackScope = (window.APP_TRANSLATIONS || {}).en || {};

  $panel.find('[data-i18n]').each(function () {
    const $node = $(this);
    const key = $node.attr('data-i18n');
    if (!key) {
      return;
    }

    const translated =
      getNestedValue(scope, key) || getNestedValue(fallbackScope, key);
    if (!translated) {
      return;
    }

    const attrName = $node.attr('data-i18n-attr');
    if (attrName) {
      $node.attr(attrName, translated);
      return;
    }

    $node.text(translated);
  });
}

function buildWheelItems() {
  const stripWellnessFromTitle = function (title, fallback) {
    const source = String(title || '').trim();
    if (!source) {
      return fallback;
    }

    const stripped = source
      .replace(/\bwellness\b/gi, '')
      .replace(/\s{2,}/g, ' ')
      .trim();

    return stripped || fallback;
  };

  const getIconDataUri = function (iconSvg) {
    if (!iconSvg) {
      return '';
    }

    const iconForWheel = iconSvg.replace(
      /stroke="currentColor"/g,
      'stroke="white"',
    );
    return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(iconForWheel)}`;
  };

  const scope = getTranslationScope();
  const organizations = scope.organizations;
  const wheel = scope.wheel;

  return WHEEL_META.map(function (meta) {
    const panelTitle = organizations[meta.titleKey] || meta.canonicalTitle;
    const wheelTitle = stripWellnessFromTitle(panelTitle, meta.canonicalTitle);
    const subs = meta.subKeys.map(function (key) {
      // "Other" filters by a dimension-specific catch-all key; the rest by their
      // own subcategory key. filterKey is what the organizations page matches on.
      var filterKey =
        key === 'wellness_physical_other' ? meta.key + '_other' : key;
      return {
        key: key,
        filterKey: filterKey,
        label: organizations[key] || wheel[key] || key,
      };
    });

    return {
      icon: meta.icon || '',
      iconDataUri: getIconDataUri(meta.icon || ''),
      color: meta.color,
      title: wheelTitle,
      panelTitle: panelTitle,
      desc: wheel[meta.descriptionKey] || '',
      subs: subs,
      matchTokens: [
        meta.key.toLowerCase(),
        meta.canonicalTitle.toLowerCase(),
        String(wheelTitle).toLowerCase(),
        String(panelTitle).toLowerCase(),
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
  const $container = $(container);
  if (!$container.length || $container.hasClass('ww-wheel-instance')) {
    return;
  }

  const isCentered = $container.is('[data-wheel-centered]');

  const sizeAttr = parseFloat($container.attr('data-wheel-size'));
  if (!Number.isNaN(sizeAttr) && sizeAttr > 0) {
    size = sizeAttr;
  }

  const wheelScale = size / 340;
  const scaledPx = function (base, min) {
    return Math.max(min, Math.round(base * wheelScale));
  };

  const scope = getTranslationScope();
  const ALL = buildWheelItems();

  const attrValue = $container.attr('data-active-categories') || '';
  const allowedTitles = attrValue
    .split(',')
    .map((s) => s.trim().toLowerCase())
    .filter(Boolean);
  const ENABLED = ALL.filter((d) =>
    d.matchTokens.some((token) => allowedTitles.includes(token)),
  );
  if (!ENABLED.length) return;

  // When present (the established wheel), restrict each dimension's listed
  // subcategories to the org's actual established services. Absent on the home
  // and emerging wheels, where all subs are shown.
  const subcatAttr = $container.attr('data-active-subcats');
  const allowedSubcats =
    subcatAttr == null
      ? null
      : subcatAttr
          .split(',')
          .map((s) => s.trim().toLowerCase())
          .filter(Boolean);

  // unique id prefix per instance
  const uid = 'ww-' + Math.random().toString(36).slice(2, 7);

  $container.addClass('ww-wheel-instance');

  const $svgWrap = $('<div>')
    .addClass('ww-svg-wrap')
    .css({
      width: size + 'px',
      height: size + 'px',
      overflow: 'visible',
    });
  const $panelsEl = $('<div>').addClass('ww-panel-wrap');
  const $panelInner = $('<div>').addClass('ww-panel-inner');
  const $defaultMsg = $('<div>')
    .addClass('default-msg')
    .text(scope.wheel.default_message || WHEEL_DEFAULT_MESSAGE);
  $panelInner.append($defaultMsg);
  $panelsEl.append($panelInner);

  const $wrap = $('<div>').addClass('ww-wrap');
  if (isCentered) $wrap.addClass('ww-centered');
  $container.append($wrap.append($svgWrap, $panelsEl));

  if (isCentered) {
    $panelsEl.css('left', size + 32 + 'px');
  }

  // build panels
  ENABLED.forEach((d, i) => {
    // Every subcategory (including "Other") links to the organizations list,
    // pre-filtered to orgs that provide it as an established service. When
    // data-active-subcats is set (established wheel), subs are further filtered
    // to only the org's own established services.
    const subs =
      allowedSubcats == null
        ? d.subs
        : d.subs.filter((s) =>
            allowedSubcats.includes(String(s.filterKey).toLowerCase()),
          );
    const subItems = subs
      .map((s) => {
        const dot = `<span class="dot" style="background:${d.color}"></span>`;
        const cls = 'subcat-name subcat-link';
        const name = `<a class="${cls}" href="#!/organizations?subcat=${encodeURIComponent(s.filterKey)}">${s.label}</a>`;
        return `<li>${dot}${name}</li>`;
      })
      .join('');
    const $panel = $('<div>')
      .addClass('panel')
      .attr('id', uid + '-panel-' + i)
      .html(
        `<p class="panel-title" style="color:${d.color}">${d.panelTitle || d.title}</p>
      <p class="panel-desc">${d.desc}</p>
      <ul class="subcats">${subItems}</ul>`,
      );
    if (d.icon) {
      $panel.attr('data-icon', d.icon);
    }
    $panelInner.append($panel);
  });

  // SVG.js instance
  const draw = SVG()
    .addTo($svgWrap[0])
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

  let centeredTimer = null;

  const updateCenteredLayout = function (isActive) {
    if (!isCentered) return;
    window.clearTimeout(centeredTimer);
    if (isActive) {
      const offset = Math.max(0, ($wrap.width() - size) / 2);
      $svgWrap.css('transform', 'translateX(-' + offset + 'px)');
      centeredTimer = window.setTimeout(function () {
        $wrap.addClass('ww-has-active');
      }, 560);
    } else {
      $wrap.removeClass('ww-has-active');
      centeredTimer = window.setTimeout(function () {
        $svgWrap.css('transform', '');
      }, 210);
    }
  };

  function showPanel(idx) {
    $panelsEl.find('.panel').removeClass('visible');
    if (idx >= 0) {
      $defaultMsg.hide();
      $panelsEl.find('#' + uid + '-panel-' + idx).addClass('visible');
      updateCenteredLayout(true);
    } else {
      if (!isCentered) $defaultMsg.show();
      updateCenteredLayout(false);
    }
  }

  function applyState() {
    wheelGroup
      .animate(DUR, '<>')
      .transform({ rotate: currentRotation, ox: CX, oy: CY });
    Object.entries(segMap).forEach(([i, s]) => {
      const idx = parseInt(i);

      if (s.content && s.cp) {
        s.content
          .animate(DUR, '<>')
          .transform({ rotate: -currentRotation, ox: s.cp.x, oy: s.cp.y });
      }

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
      const content = g.group();
      const iconTextGap = scaledPx(8, 4);
      const singleIconSize = scaledPx(36, 18) * 1.5;
      const singleIconYOffset = scaledPx(18, 9) * 1.5;
      const iconPoint = { x: CX, y: CY - singleIconYOffset };
      const contentPivot = { x: CX, y: CY };
      const singleLabelY = d.iconDataUri
        ? iconPoint.y + singleIconSize / 2 + iconTextGap + scaledPx(5, 3)
        : CY;

      if (d.iconDataUri) {
        content
          .image(d.iconDataUri)
          .size(singleIconSize, singleIconSize)
          .center(iconPoint.x, iconPoint.y);
      }

      content
        .text(d.title)
        .font({
          family: 'sans-serif',
          size: 16,
          weight: '600',
          anchor: 'middle',
        })
        .fill('white')
        .center(CX, singleLabelY);

      segMap[0] = {
        group: g,
        content,
        midDeg: 0,
        cp: contentPivot,
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
      if (d.icon) {
        g.attr('data-icon', d.icon);
      }
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

      const hasIcon = Boolean(d.iconDataUri);
      const iconTextGap = scaledPx(5, 3);
      const iconSize = (sweep < 50 ? scaledPx(20, 10) : scaledPx(26, 13)) * 1.5;
      const iconPoint = { x: lp.x, y: lp.y - (hasIcon ? 12 : 0) };
      const labelPoint = hasIcon
        ? {
            x: lp.x,
            y: iconPoint.y + iconSize / 2 + iconTextGap + scaledPx(3, 2),
          }
        : { x: lp.x, y: lp.y };
      const contentPivot = { x: lp.x, y: lp.y };
      const content = g.group();

      if (hasIcon) {
        content
          .image(d.iconDataUri)
          .size(iconSize, iconSize)
          .center(iconPoint.x, iconPoint.y);
      }

      content
        .text(d.title)
        .addClass('mt-1')
        .font({
          family: 'sans-serif',
          size: Math.max(7.5, labelSize),
          weight: '600',
          anchor: 'middle',
        })
        .fill('white')
        .center(labelPoint.x, labelPoint.y);

      segMap[i] = {
        group: g,
        content,
        midDeg,
        cp: contentPivot,
        tx: 0,
        ty: 0,
      };

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

  if (isCentered && window.ResizeObserver) {
    const resizeObserver = new ResizeObserver(function () {
      if (activeSegIdx >= 0) {
        const offset = Math.max(0, ($wrap.width() - size) / 2);
        $svgWrap.css({
          transition: 'none',
          transform: 'translateX(-' + offset + 'px)',
        });
        window.requestAnimationFrame(function () {
          $svgWrap.css('transition', '');
        });
      }
    });
    resizeObserver.observe($wrap[0]);
  }
}

window.createWheel = createWheel;

$(function () {
  var $body = $('body');
  $body.addClass('app-ready');
  applyThemeSettingsTranslations();

  // Fade the page in only once shiny.router has shown the route that matches the
  // current URL. On a deep link the router briefly activates the default ("/")
  // route before switching to the requested one, so revealing on the first
  // resolved route would flash the home page. We wait until the visible route's
  // data-path matches the hash.
  var revealApp = function () {
    $body.addClass('router-ready');
  };
  var normPath = function (p) {
    return p === '/' || p == null ? '' : p;
  };
  var hashRoutePath = function () {
    var hash = window.location.hash || '';
    return normPath(hash.replace(/^#!?\/?/, '').split('?')[0] || '');
  };
  var routerMatchesHash = function () {
    var $active = $('#router-page-wrapper .router:not(.router-hidden)');
    if (!$active.length) {
      return false;
    }
    return normPath($active.attr('data-path')) === hashRoutePath();
  };
  if (routerMatchesHash()) {
    revealApp();
  } else {
    // MutationObserver has no jQuery equivalent; keep it native.
    var wrapper = document.getElementById('router-page-wrapper');
    if (wrapper && window.MutationObserver) {
      var routerObserver = new MutationObserver(function () {
        if (routerMatchesHash()) {
          revealApp();
          routerObserver.disconnect();
        }
      });
      routerObserver.observe(wrapper, {
        attributes: true,
        subtree: true,
        attributeFilter: ['class'],
      });
    }
    // Safety net: never leave the page hidden if the signal is missed.
    window.setTimeout(revealApp, 4000);
  }

  // The marketing/gradient body styling applies only to the home route ("#!/").
  var HOME_BODY_CLASSES = 'body-marketing body-gradient';
  var updateHomeBodyClasses = function () {
    var path = (window.location.hash || '')
      .replace(/^#!?\/?/, '')
      .split('?')[0];
    var isHome = path === '' || path === '/';
    $body.toggleClass(HOME_BODY_CLASSES, isHome);
  };
  updateHomeBodyClasses();
  $(window).on('hashchange', updateHomeBodyClasses);
  $(document).on('shiny:value', updateHomeBodyClasses);

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
    $('a[href*="#!/"]').each(function () {
      var $anchor = $(this);
      var href = $anchor.attr('href');
      var mergedHref = mergeCurrentSearchIntoRouterHref(href);
      if (mergedHref && mergedHref !== href) {
        $anchor.attr('href', mergedHref);
      }
    });
  };

  var refreshQueryParams = function () {
    queryParams = parseSearchParams(window.location.search);
    syncRouterLinksWithQueryParams();
    return queryParams;
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

  var $settingsForm = $('#offcanvasSettings');
  var checkItems = function () {
    if (!$settingsForm.length) {
      return;
    }
    Object.keys(themeConfig).forEach(function (key) {
      var value = window.localStorage['tabler-' + key] || themeConfig[key];
      if (value) {
        $settingsForm.find('[name="' + key + '"]').each(function () {
          $(this).prop('checked', this.value === value);
        });
      }
    });
  };

  $settingsForm.on('change', function (event) {
    refreshQueryParams();
    var name = event.target.name;
    var value = event.target.value;
    if (Object.prototype.hasOwnProperty.call(themeConfig, name)) {
      $('html').attr('data-bs-' + name, value);
      window.localStorage.setItem('tabler-' + name, value);
      setParam(name, value);
    }
    pushQuery();
  });

  $(document).on('click', '#reset-changes', function () {
    refreshQueryParams();
    Object.keys(themeConfig).forEach(function (key) {
      $('html').removeAttr('data-bs-' + key);
      window.localStorage.removeItem('tabler-' + key);
      deleteParam(key);
    });
    checkItems();
    pushQuery();
  });

  checkItems();
  syncRouterLinksWithQueryParams();

  // Merge the current ?lang=... search into router links at click time.
  $(document).on('click', 'a[href]', function (event) {
    var href = $(this).attr('href');
    var mergedHref = mergeCurrentSearchIntoRouterHref(href);
    if (mergedHref && mergedHref !== href) {
      event.preventDefault();
      window.location.assign(mergedHref);
    }
  });

  // Live, client-side filtering of the organizations list. The list is rendered
  // server-side; the search box and the established-area checkboxes just show/hide
  // cards. A checkbox carrying data-filter-subcat filters by that specific
  // subcategory (matched against data-established-subcats); any other checked box
  // filters by its dimension (matched against data-established). A card passes
  // when its name contains the query AND, if anything is selected, it matches at
  // least one selected dimension or subcategory.
  var collectSelection = function () {
    var dims = [];
    var subs = [];
    $('[data-filter-group]:checked').each(function () {
      var $box = $(this);
      var sub = $box.attr('data-filter-subcat');
      if (sub) {
        subs.push(sub);
      } else {
        dims.push($box.attr('data-filter-dimension'));
      }
    });
    return { dims: dims, subs: subs };
  };

  var cardAreas = function ($card, attr) {
    return ($card.attr(attr) || '').split(',').filter(Boolean);
  };

  var intersects = function (selected, areas) {
    return selected.some(function (item) {
      return areas.indexOf(item) !== -1;
    });
  };

  var filterOrganizations = function () {
    var $cards = $('.organization-result');
    if (!$cards.length) {
      return;
    }

    var query = ($('#organizations-search').val() || '').trim().toLowerCase();
    var sel = collectSelection();
    var hasAreaFilter = sel.dims.length > 0 || sel.subs.length > 0;
    var visible = 0;

    $cards.each(function () {
      var $card = $(this);
      var name = $card.attr('data-org-name') || '';
      var areaMatch =
        !hasAreaFilter ||
        intersects(sel.dims, cardAreas($card, 'data-established')) ||
        intersects(sel.subs, cardAreas($card, 'data-established-subcats'));
      var show = (!query || name.indexOf(query) !== -1) && areaMatch;
      $card.toggleClass('d-none', !show);
      if (show) {
        visible += 1;
      }
    });

    $('#organizations-no-results').toggleClass('d-none', visible !== 0);
  };

  $(document).on('input', '#organizations-search', filterOrganizations);

  $(document).on('change', '[data-filter-group]', function () {
    var $box = $(this);
    // Toggling a dimension (parent) toggles all of its sub-category children.
    if ($box.attr('data-filter-role') === 'parent') {
      var selector =
        '[data-filter-group="' +
        $box.attr('data-filter-group') +
        '"][data-filter-dimension="' +
        $box.attr('data-filter-dimension') +
        '"][data-filter-role="child"]';
      $(selector).prop('checked', $box.prop('checked'));
    }
    filterOrganizations();
  });

  // Reset clears the search box and all checkboxes, then re-filters.
  $(document).on('click', '#organizations-filter-reset', function () {
    $('#organizations-search').val('');
    $('[data-filter-group]:checked').prop('checked', false);
    filterOrganizations();
  });

  // Deep link from a wheel subcategory: #!/organizations?subcat=<key>. On arrival,
  // tick that subcategory checkbox once and filter. Guarded so it applies a given
  // subcat a single time and never fights subsequent user interaction.
  var appliedSubcat = null;
  var hashSubcat = function () {
    var hash = window.location.hash || '';
    var q = hash.indexOf('?');
    if (q < 0) {
      return '';
    }
    var params = parseSearchParams(hash.slice(q));
    return params.subcat || '';
  };

  var applyDeepLinkFilter = function () {
    var subcat = hashSubcat();
    if (!subcat || subcat === appliedSubcat) {
      return;
    }
    var $box = $('[data-filter-subcat="' + subcat + '"]');
    if (!$box.length) {
      return;
    }
    appliedSubcat = subcat;
    $('[data-filter-group]:checked').prop('checked', false);
    $box.prop('checked', true);
    filterOrganizations();
  };

  // Re-apply the active filter after Shiny/router re-renders the list.
  $(document).on('shiny:value', function () {
    filterOrganizations();
    applyDeepLinkFilter();
  });
  $(window).on('hashchange', applyDeepLinkFilter);
  applyDeepLinkFilter();

  var initWheels = function () {
    $('[data-active-categories]').each(function () {
      createWheel(this, 440);
    });
  };

  var initWheelsNowAndNextTick = function () {
    applyThemeSettingsTranslations();
    initWheels();
    window.setTimeout(initWheels, 0);
  };

  initWheelsNowAndNextTick();

  // Shiny/router render content after load, so re-run wheel setup when outputs
  // update, hash navigation changes, or DOM nodes are injected.
  $(document).on('shiny:value', initWheelsNowAndNextTick);
  $(window).on('hashchange', initWheelsNowAndNextTick);

  // MutationObserver has no jQuery equivalent; keep it native.
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

    var total = $('[data-active-categories]').length;
    var initialized = $('[data-active-categories].ww-wheel-instance').length;

    if ((total > 0 && total === initialized) || wheelInitAttempts >= 20) {
      window.clearInterval(wheelInitTimer);
    }
  }, 300);
});
