mergeInto(LibraryManager.library, {
  js_rcheevos_server_request: function(request_id, urlPtr, postPtr) {
    const url = UTF8ToString(urlPtr);
    const post = postPtr ? UTF8ToString(postPtr) : null;

    // Call your application's JS (must be implemented on your side)
    if (Module.onRcheevosServerRequest) {
      Module.onRcheevosServerRequest(request_id, url, post);
    }
  },

  js_rcheevos_event_achievement: function(achievement_id) {
    if (Module.onRcheevosAchievementUnlocked) {
      Module.onRcheevosAchievementUnlocked(achievement_id);
    }
  }
});