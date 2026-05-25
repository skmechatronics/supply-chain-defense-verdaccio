'use strict';

module.exports = function CooldownFilter(config, options) {
  const logger = options.logger;
  const minAgeDays = config.minAgeDays || 7;
  const overrides = parseOverrides(process.env.PACKAGE_OVERRIDES || '');
  const blocks = parseOverrides(process.env.PACKAGE_BLOCKS || '');

  logger.info(
    { minAgeDays, overrides: [...overrides], blocks: [...blocks] },
    'cooldown-filter: initialized (minAgeDays=@{minAgeDays}, overrides=@{overrides}, blocks=@{blocks})'
  );

  return {
    filter_metadata(packageInfo, callback) {
      const { versions = {}, time = {} } = packageInfo;
      const distTags = { ...(packageInfo['dist-tags'] || {}) };
      const name = packageInfo.name;

      const filteredVersions = {};
      for (const [version, versionData] of Object.entries(versions)) {
        if (isOverridden(blocks, name, version)) continue;
        const publishTime = time[version];
        if (!publishTime || !isTooNew(publishTime, minAgeDays) || isOverridden(overrides, name, version)) {
          filteredVersions[version] = versionData;
        }
      }

      for (const [tag, version] of Object.entries(distTags)) {
        if (!filteredVersions[version]) {
          if (tag === 'latest') {
            const newest = newestSurviving(filteredVersions, time);
            if (newest) {
              distTags[tag] = newest;
            } else {
              delete distTags[tag];
            }
          } else {
            delete distTags[tag];
          }
        }
      }

      packageInfo.versions = filteredVersions;
      packageInfo['dist-tags'] = distTags;
      callback(null);
    }
  };
};

function parseOverrides(str) {
  const set = new Set();
  for (const entry of str.split(',')) {
    const trimmed = entry.trim();
    if (trimmed) set.add(trimmed);
  }
  return set;
}

function isOverridden(overrides, packageName, version) {
  return overrides.has(`${packageName}@${version}`);
}

function isTooNew(publishTime, minAgeDays) {
  const ageDays = (Date.now() - new Date(publishTime).getTime()) / 86400000;
  return ageDays < minAgeDays;
}

function newestSurviving(versions, time) {
  return Object.keys(versions)
    .filter(v => time[v])
    .sort((a, b) => new Date(time[b]) - new Date(time[a]))[0] || null;
}
