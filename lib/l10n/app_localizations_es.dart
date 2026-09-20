// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Sudoku159';

  @override
  String get navHome => 'Inicio';

  @override
  String get navChallenge => 'Desafío';

  @override
  String get navRecords => 'Registros';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get recordsScreenTitle => 'Registros y estadísticas';

  @override
  String get challengeScreenTitle => 'Desafío';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSectionNotifications => 'Notificaciones';

  @override
  String get settingsSectionLanguage => 'Idioma';

  @override
  String get settingsSectionGame => 'Juego';

  @override
  String get settingsSectionInfo => 'Acerca de';

  @override
  String get settingsNotificationsTitle => 'Ajustes de notificaciones';

  @override
  String get settingsNotificationsSubtitle =>
      'Enviar un recordatorio cuando el desafío de hoy siga sin completarse';

  @override
  String get settingsStreakReminderTitle => 'Recordatorio de racha';

  @override
  String get settingsStreakReminderSubtitle =>
      'Enviar un recordatorio más cuando ya tengas una racha activa';

  @override
  String get settingsNotificationTimeTitle => 'Hora de la notificación';

  @override
  String get settingsNotificationTimeSubtitle =>
      'Elige cuándo recibir los recordatorios';

  @override
  String get settingsNotificationsPermissionDenied =>
      'Se necesita permiso de notificaciones para activar los recordatorios.';

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsLanguageSubtitle => 'Cambiar el idioma de la app';

  @override
  String get settingsLanguageSystem => 'Predeterminado del sistema';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageKorean => '한국어';

  @override
  String get settingsLanguageJapanese => '日本語';

  @override
  String get settingsLanguageChinese => '中文';

  @override
  String get settingsLanguageSpanish => 'Español';

  @override
  String get settingsLanguagePickerTitle => 'Elegir idioma';

  @override
  String get settingsVibrationTitle => 'Vibración táctil';

  @override
  String get settingsVibrationSubtitle => 'Vibrar al introducir números';

  @override
  String get settingsKeepScreenAwakeTitle => 'Mantener la pantalla activa';

  @override
  String get settingsKeepScreenAwakeSubtitle =>
      'Evitar que la pantalla de juego se apague automáticamente';

  @override
  String get settingsOneHandModeTitle => 'Modo una mano';

  @override
  String get settingsOneHandModeSubtitle =>
      'Usar una disposición de botones más compacta en la pantalla de juego';

  @override
  String get settingsMemoHighlightTitle => 'Resaltado de notas';

  @override
  String get settingsMemoHighlightSubtitle =>
      'Mostrar el foco de notas, candidatos y resaltados de nota única';

  @override
  String get settingsSmartHintTitle => 'Resaltado de celdas jugables';

  @override
  String get settingsSmartHintSubtitle =>
      'Resaltar suavemente las celdas que se pueden completar de inmediato según las reglas';

  @override
  String get settingsAppInfoTitle => 'Información de la app';

  @override
  String get settingsAppInfoSubtitle =>
      'Versión e información del desarrollador';

  @override
  String get settingsPrivacyTitle => 'Política de privacidad';

  @override
  String get settingsPrivacySubtitle => 'Cómo manejamos tus datos';

  @override
  String get settingsTabletNotificationsHeader => 'Ajustes de notificaciones';

  @override
  String get settingsTabletNotificationsBody =>
      'Gestiona y configura las notificaciones del juego.';

  @override
  String get settingsGameCompleteNotifTitle =>
      'Notificación de partida completada';

  @override
  String get settingsGameCompleteNotifSubtitle =>
      'Avisarte cuando termines un puzle';

  @override
  String get settingsDailyGoalNotifTitle => 'Notificación de objetivo diario';

  @override
  String get settingsDailyGoalNotifSubtitle =>
      'Celebrar el momento en que alcances tu objetivo semanal';

  @override
  String get settingsHintNotifTitle => 'Notificación de uso de pista';

  @override
  String get settingsHintNotifSubtitle => 'Avisarte cuando uses una pista';

  @override
  String get levelBeginner => 'Principiante';

  @override
  String get levelIntermediate => 'Intermedio';

  @override
  String get levelAdvanced => 'Avanzado';

  @override
  String get levelExpert => 'Experto';

  @override
  String get levelMaster => 'Maestro';

  @override
  String get levelDescBeginner => 'Perfecto si eres nuevo en el sudoku';

  @override
  String get levelDescIntermediate => 'Para quienes conocen las reglas básicas';

  @override
  String get levelDescAdvanced => 'Para jugadores con experiencia';

  @override
  String get levelDescExpert => 'Para maestros del sudoku';

  @override
  String get levelDescMaster => 'El desafío definitivo';

  @override
  String gameNumberLabel(int number) {
    return 'Partida $number';
  }

  @override
  String get gameHintShort => 'Pista';

  @override
  String get gameUndoShort => 'Deshacer';

  @override
  String get gameRedoShort => 'Rehacer';

  @override
  String get gameMemoShort => 'Notas';

  @override
  String gameCellLabel(int row, int col, String content) {
    return 'Fila $row, columna $col: $content';
  }

  @override
  String get gameCellEmpty => 'vacía';

  @override
  String gameCellNotes(String notes) {
    return 'notas $notes';
  }

  @override
  String get gameCellGiven => 'dado';

  @override
  String get gameCellHint => 'pista';

  @override
  String get gameCellWrong => 'incorrecto';

  @override
  String get gameEraseShort => 'Borrar';

  @override
  String get gameMoreOptions => 'Más opciones';

  @override
  String get gameMemoOnShort => 'Notas ON';

  @override
  String get gameMemoStateOn => 'ON';

  @override
  String get gameMemoStateOff => 'OFF';

  @override
  String get gameMemoFocusShort => 'Foco';

  @override
  String get gameMemoFocusIdle => 'Ninguno';

  @override
  String get gameWrongShort => 'Errores';

  @override
  String get gamePerfectShort => 'Perfecto';

  @override
  String get gamePerfectReady => 'Activo';

  @override
  String get gamePerfectMissed => 'Perdido';

  @override
  String get gameProgressShort => 'Progreso';

  @override
  String get gameTimeShort => 'Tiempo';

  @override
  String get gameNumberInputTitle => 'Entrada de números';

  @override
  String gameRowsCompleted(int count) {
    return '$count fila completada';
  }

  @override
  String gameColsCompleted(int count) {
    return '$count columna completada';
  }

  @override
  String gameBoxesCompleted(int count) {
    return '$count caja completada';
  }

  @override
  String get gamePause => 'Pausa';

  @override
  String get gameResume => 'Reanudar';

  @override
  String get gameAnswerPreview => 'Respuesta';

  @override
  String get challengeCompletedToday => '¡Completaste el desafío de hoy!';

  @override
  String get shareCopySuccess => 'Resultado copiado al portapapeles.';

  @override
  String get shareSubject => 'Resultado de Sudoku159';

  @override
  String get shareClearHeader => 'Sudoku159 completado';

  @override
  String shareClearLine(String level, int number) {
    return '$level · Partida $number';
  }

  @override
  String shareClearStats(String time, int wrong) {
    return '$time · $wrong errores';
  }

  @override
  String get shareClearTags => '#Sudoku159 #SudokuChallenge';

  @override
  String shareSummaryPattern(String time, int wrong) {
    return '$time · $wrong errores';
  }

  @override
  String get dialogCongratulations => '¡Felicidades!';

  @override
  String get dialogNewBest => 'NUEVO RÉCORD';

  @override
  String get dialogSudokuComplete => '¡Completaste el sudoku!';

  @override
  String get dialogNewBadges => 'Nuevas insignias';

  @override
  String get dialogElapsedTime => 'Tiempo';

  @override
  String get dialogWrongCount => 'Errores';

  @override
  String dialogWrongCountValue(int count) {
    return '$count veces';
  }

  @override
  String get dialogSharePreview => 'Texto para compartir';

  @override
  String get dialogCopyResult => 'Copiar';

  @override
  String get dialogShare => 'Compartir';

  @override
  String get dialogBackToLevels => 'Lista de puzles';

  @override
  String get dialogPlayAgain => 'Resolver de nuevo';

  @override
  String get dialogPuzzleCompleteTitle => 'Puzle completado';

  @override
  String get dialogNewBestMessage => '¡Nuevo mejor registro!';

  @override
  String dialogHintsUsed(int count) {
    return 'Pistas usadas: $count';
  }

  @override
  String get dialogSolveSameAgain => 'Resolver este puzle de nuevo';

  @override
  String get dialogNextPuzzle => 'Siguiente puzle';

  @override
  String get updateRequiredTitle => 'Actualización necesaria';

  @override
  String get updateRequiredMessage =>
      'Hay una nueva versión de esta app disponible.\nActualiza para seguir jugando.';

  @override
  String get updateNowButton => 'Actualizar ahora';

  @override
  String get settingsNotificationsComingSoonTitle => 'Notificaciones';

  @override
  String get settingsNotificationsComingSoonBody =>
      'Los recordatorios push y las opciones de notificación estarán disponibles en una futura actualización. ¡Gracias por tu paciencia!';

  @override
  String get settingsAboutDialogTitle => 'Acerca de esta app';

  @override
  String settingsAboutVersionLabel(String version) {
    return 'Versión $version';
  }

  @override
  String get settingsAboutDeveloperNote => '¡Disfruta jugando Sudoku159!';

  @override
  String get settingsAboutSupportEmail => '· team929.support@gmail.com';

  @override
  String get commonOk => 'Aceptar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get gameOverTitle => 'Has alcanzado el límite de errores';

  @override
  String get gameOverMessage =>
      'Puedes empezar este puzle de nuevo o elegir otro.';

  @override
  String gameOverWrongLabel(int count, int maxCount) {
    return 'Esta partida: $count errores / límite $maxCount';
  }

  @override
  String get recordsFilterSectionTitle => 'Filtros';

  @override
  String get recordsFilterAllLevels => 'Todos los niveles';

  @override
  String get recordsPeriodLabel => 'Periodo';

  @override
  String get recordsPeriodAll => 'Todo el tiempo';

  @override
  String recordsPeriodLastDays(int days) {
    return 'Últimos $days días';
  }

  @override
  String get recordsSummaryTitle => 'Últimos 7 días';

  @override
  String get recordsTrendTitle => 'Tendencia de los últimos 7 días';

  @override
  String get recordsTrendEmpty =>
      'No hay suficientes victorias recientes para mostrar una tendencia de 7 días.';

  @override
  String get recordsTrendClears => 'Victorias';

  @override
  String get recordsTrendActiveDays => 'Días jugados';

  @override
  String get recordsTrendWindowAvgTime => 'Tiempo prom. (mismo periodo)';

  @override
  String get recordsTrendWindowAvgWrong => 'Errores prom. (mismo periodo)';

  @override
  String get recordsHeroBadgeFlow => 'Ritmo';

  @override
  String get recordsHeroTitle => 'Empieza con la forma\nsuave de tu progreso.';

  @override
  String get recordsHeroSubtitle =>
      'La curva de arriba es la misma semana, suavizada para verla rápido. Usa la tarjeta de abajo para ver las victorias exactas por día.';

  @override
  String get recordsInsightThisWeekEyebrow => 'Esta semana';

  @override
  String recordsInsightClearsValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count victorias',
      one: '$count victoria',
    );
    return '$_temp0';
  }

  @override
  String get recordsInsightAvgPaceEyebrow => 'Ritmo promedio';

  @override
  String get recordsTrendSectionSubtitle =>
      'Victorias día a día de los últimos siete días.';

  @override
  String get recordsTrendLegendDailyClears => 'Victorias diarias';

  @override
  String get recordsTrendTodayLabel => 'Hoy';

  @override
  String get recordsPlayInsightsTitle => 'Esta semana';

  @override
  String get recordsPlayCalendarTitle => 'Por día';

  @override
  String get recordsWeeklyReportTitle => 'Informe semanal';

  @override
  String get recordsWeeklyReportBusiestDay => 'Día más activo';

  @override
  String recordsWeeklyReportTopDayValue(String day, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count victorias',
      one: '$count victoria',
    );
    return '$day, $_temp0';
  }

  @override
  String get recordsWeeklyReportTopDayFallback => 'Aún sin victorias';

  @override
  String get recordsTimelineTitle => 'Cronología reciente';

  @override
  String get recordsTimelineEmpty =>
      'Las victorias recientes aparecerán aquí a medida que juegues.';

  @override
  String recordsTimelineMistakesValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count errores',
      one: '$count error',
    );
    return '$_temp0';
  }

  @override
  String get recordsTimelinePerfect => 'Victoria perfecta';

  @override
  String get recordsPaceTitle => 'Cambio de ritmo';

  @override
  String get recordsPaceEmpty =>
      'Necesitamos otra semana de registros antes de poder comparar tu ritmo.';

  @override
  String get recordsPaceRecentWindow => 'Últimos 7 días';

  @override
  String get recordsPacePreviousWindow => '7 días anteriores';

  @override
  String get recordsPaceDelta => 'Cambio';

  @override
  String get recordsMetricClears => 'Victorias (filtradas)';

  @override
  String get recordsMetricClearRate => 'Puzles completados';

  @override
  String get recordsMetricPerfectRate => 'Sin errores';

  @override
  String get recordsSummaryMetricsFootnote =>
      'Cada puzle cuenta una vez, con su mejor registro, y sigue tus filtros activos. El progreso compara esos puzles con el total del mismo ámbito.';

  @override
  String get recordsMetricAvgTime => 'Media de mejores tiempos';

  @override
  String get recordsMetricAvgWrong => 'Errores medios (mejores)';

  @override
  String get recordsByLevelTitle => 'Registros por nivel';

  @override
  String get recordsByLevelEmpty => 'No hay estadísticas para este filtro.';

  @override
  String get recordsByLevelSectionSubtitle =>
      'Descubre en qué niveles te sientes cada vez más cómodo.';

  @override
  String get recordsLevelInfographicClearRate => 'Puzles completados';

  @override
  String get recordsLevelMiniBest => 'Mejor';

  @override
  String get recordsLevelMiniPerfectRate => 'Perfectas';

  @override
  String get recordsLevelMiniAvgWrong => 'Errores prom.';

  @override
  String get recordsStatsLoadError =>
      'No se pudieron cargar las estadísticas. Inténtalo de nuevo en unos momentos.';

  @override
  String get recordsRetry => 'Reintentar';

  @override
  String get recordsEmptyTitle =>
      'Tus registros aparecerán cuando termines tu primer puzle.';

  @override
  String get recordsEmptyAction => 'Empezar un puzle';

  @override
  String get recordsLevelEmpty =>
      'Aún no hay puzles completados en este nivel.';

  @override
  String get recordsRowBestTime => 'Mejor tiempo';

  @override
  String get recordsAverageBasisNote =>
      'Los promedios usan el mejor registro de cada puzle, no todas las partidas.';

  @override
  String get recordsCalendarTitle => 'Calendario de actividad';

  @override
  String recordsCalendarPeriod(int weeks) {
    return 'Últimas $weeks semanas';
  }

  @override
  String get recordsViewAchievements => 'Ver logros';

  @override
  String recordsOverallNote(int cleared, int total) {
    return '$cleared de $total puzles completados en todos los niveles.';
  }

  @override
  String recordsWeekActiveDays(int count) {
    return 'Días activos: $count';
  }

  @override
  String recordsWeekCompletions(int count) {
    return 'Completados: $count';
  }

  @override
  String recordsWeekDayDone(String day, int count) {
    return '$day: $count completados';
  }

  @override
  String recordsWeekDayNone(String day) {
    return '$day: sin completados';
  }

  @override
  String get recordsStatsPageSubtitle =>
      'Victorias y tiempo promedio de un vistazo.';

  @override
  String get recordsKpiWeeklyClearsLabel => 'Puzles completados';

  @override
  String get recordsKpiAvgSolveTimeLabel => 'Media de mejores tiempos';

  @override
  String get recordsActivityOverviewTitle => 'Resumen de actividad';

  @override
  String get recordsActivityHeatmapTitle => 'Actividad reciente';

  @override
  String get recordsActivityHeatmapCaption =>
      'Cuanto más oscura la casilla, más completados ese día.';

  @override
  String get recordsActivityTotalClearsLabel => 'Completados en total';

  @override
  String get recordsActivityCurrentStreakLabel => 'Racha diaria actual';

  @override
  String get recordsActivityBestStreakLabel => 'Mejor racha diaria';

  @override
  String recordsActivityDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '$count día',
    );
    return '$_temp0';
  }

  @override
  String recordsActivityClearCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count victorias',
      one: '$count victoria',
    );
    return '$_temp0';
  }

  @override
  String get recordsSectionBestRecordTitle => 'Mejor partida';

  @override
  String get recordsSectionDifficultyTitle => 'Por dificultad';

  @override
  String get recordsSectionDetailStatsTitle => 'Detalles de la sesión';

  @override
  String get recordsBestSingleEmpty => 'Aún no hay una partida destacada.';

  @override
  String get recordsHintUsageLabel => 'Pistas';

  @override
  String get recordsHintUsageNoData => 'Sin datos';

  @override
  String get recordsDetailMistakesShort => 'Errores prom.';

  @override
  String get recordsDetailStreakShort => 'Racha activa';

  @override
  String recordsDetailStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '$count día',
    );
    return '$_temp0';
  }

  @override
  String recordsStatAverageWrongFormatted(String value) {
    return '$value';
  }

  @override
  String get recordsDifficultySnapshotEmpty =>
      'Juega algunas partidas para ver aquí tu mezcla de dificultades.';

  @override
  String get recordsLevelDoneShort => 'Hecho';

  @override
  String get recordsStatsHeroEyebrow => 'Sudoku de los últimos 7 días';

  @override
  String get recordsStatsHeroHeadline =>
      'Mira de un vistazo tus\núltimos 7 días de sudoku.';

  @override
  String recordsTrendA11yMaxClears(int count) {
    return 'Máximo $count';
  }

  @override
  String get recordsHeroChartEmptyHint =>
      'Completa un puzle en los últimos 7 días para ver aquí tu curva de ritmo.';

  @override
  String get recordsHeroSubtitleNoChart =>
      'Usa la tarjeta de abajo para ver las victorias diarias de los últimos 7 días.';

  @override
  String get recordsCalendarPlayedLabel => 'Resuelto';

  @override
  String get recordsCalendarEmptyLabel => 'Sin victorias';

  @override
  String get recordsNoAverageTime => 'Sin registros';

  @override
  String get recordsStatsBasisFootnote =>
      'Las estadísticas se calculan a partir del mejor registro de cada puzle.';

  @override
  String get recordsBestByLevelTitle => 'Mejor por nivel';

  @override
  String get recordsBestByLevelEmpty =>
      'No hay mejores registros por nivel para este filtro.';

  @override
  String recordsBestByLevelDetail(String time, int wrongCount) {
    return '$time · Errores: $wrongCount';
  }

  @override
  String get recordsPerfectBadge => 'Perfecta';

  @override
  String recordsAvgTimeDetail(String time) {
    return 'Tiempo prom. $time';
  }

  @override
  String get recordsRecentTitle => 'Victorias recientes';

  @override
  String get recordsRecentEmpty =>
      'No hay victorias que coincidan con este filtro.';

  @override
  String get recordsBestTitle => 'Mejores tiempos (Top 5)';

  @override
  String get recordsBestEmpty => 'No hay mejores tiempos para este filtro.';

  @override
  String recordsGameNumberTitle(String level, int number) {
    return '$level · Partida $number';
  }

  @override
  String recordsRecentDetail(String time, int wrongCount, String date) {
    return '$time · Errores: $wrongCount · $date';
  }

  @override
  String recordsBestDetail(String time, int wrongCount) {
    return '$time · Errores: $wrongCount';
  }

  @override
  String get recordsGameLoadError =>
      'No se pudieron cargar los datos del puzle.';

  @override
  String get recordsChallengeTabHint =>
      'Los objetivos semanales y las rachas están en la pestaña Desafío.';

  @override
  String get recordsGoToChallengeTab => 'Abrir la pestaña Desafío';

  @override
  String get challengeLoadError =>
      'No se pudo cargar la información del desafío.';

  @override
  String get challengeTodaysChallengeTitle => 'Desafío de hoy';

  @override
  String get challengeTodayDoneHint =>
      'Ya terminaste el de hoy. Ábrelo de nuevo cuando quieras repasarlo.';

  @override
  String get challengeTodayPendingHint =>
      'Mantén tu racha con el puzle destacado de hoy.';

  @override
  String get challengeTodayReviewButton => 'Continuar a tu ritmo';

  @override
  String get challengeTodayStartButton => 'Empezar a tu ritmo';

  @override
  String get myPaceNoPlayableTitle => 'No hay partidas disponibles';

  @override
  String get myPaceNoPlayableMessage =>
      'No quedan puzles nuevos por jugar en ningún nivel.';

  @override
  String get challengeWeeklyGoalReachedTitle => 'Objetivo semanal alcanzado';

  @override
  String challengeWeeklyGoalRemainingTitle(int count) {
    return '$count victorias más para alcanzar tu objetivo semanal';
  }

  @override
  String get challengeWeeklyGoalReachedBody =>
      'Consigue más victorias perfectas para reforzar tu ritmo.';

  @override
  String get challengeWeeklyGoalCatchUpBody =>
      'Con unas pocas partidas más puedes completar el objetivo de esta semana.';

  @override
  String challengePerfectThisWeek(int count) {
    return '$count victorias perfectas esta semana';
  }

  @override
  String get challengePerfectThisWeekFirst =>
      'Intenta tu primera victoria perfecta esta semana';

  @override
  String get challengePerfectPositiveBody =>
      'Las partidas sin errores hacen que tu progreso se note más.';

  @override
  String get challengePerfectZeroBody =>
      'El modo notas te acerca mucho más a las victorias sin errores.';

  @override
  String get challengeWeeklyGoalHeading => 'Objetivo semanal';

  @override
  String challengeWeeklyClearsLine(int count) {
    return '$count victorias esta semana';
  }

  @override
  String challengeWeeklyProgressShort(int done, int target) {
    return '$done / $target hecho';
  }

  @override
  String challengeWeeklyPerfectShort(int count) {
    return '$count perfectas';
  }

  @override
  String get challengeWeeklyCongratsFooter =>
      'Objetivo semanal completado. ¡Sigue acumulando buenos resultados!';

  @override
  String challengeWeeklyAlmostFooter(int count) {
    return '$count victorias más para terminar la semana.';
  }

  @override
  String get challengeAchievementsHeading => 'Logros · insignias';

  @override
  String challengeBadgesCollected(int unlocked, int total) {
    return '$unlocked / $total obtenidas';
  }

  @override
  String get challengeViewAllBadges => 'Ver todas';

  @override
  String get challengeEarnedBadgesHeading => 'Insignias obtenidas';

  @override
  String get challengeNextBadgeTargets => 'Próximos objetivos';

  @override
  String challengeBadgeProgressLine(String desc, String progress) {
    return '$desc · Progreso: $progress';
  }

  @override
  String challengeStreakDays(int days) {
    return 'Racha de $days días';
  }

  @override
  String get challengeStreakStartToday => 'Consigue tu primera victoria hoy';

  @override
  String get challengeTabHeroHeadline =>
      'El puzle de hoy y tu ritmo semanal,\nen una sola vista tranquila.';

  @override
  String get challengeHeroPendingDetail =>
      'Empieza a jugar desde Inicio o usa el botón de abajo.';

  @override
  String get challengeHeroDoneDetail =>
      'El desafío de hoy está completo. Las insignias y el progreso semanal se guardan en esta pestaña.';

  @override
  String get challengeOpenTodayOnHomeButton =>
      'Abrir el puzle de hoy en Inicio';

  @override
  String get challengeHeroDoneCaption =>
      'Terminaste el desafío de hoy. Vuelve mañana para extender tu racha.';

  @override
  String get challengeHeroPendingCaption =>
      'El puzle de hoy sigue abierto: empieza ahora para mantener viva tu racha.';

  @override
  String get homeGuestTitle => 'Viajero';

  @override
  String get homeGuestSubtitle => 'Empieza una partida con un solo toque';

  @override
  String get homeContinueTitle => 'Reanudar';

  @override
  String homeContinueSubtitle(String level, int gameNumber, int cells) {
    return '$level · Partida $gameNumber · $cells celdas completadas';
  }

  @override
  String get homeContinueDescription =>
      'Retoma tu puzle pausado justo donde lo dejaste.';

  @override
  String get homeContinueSameAsSpotlightSupporting =>
      'Reanudar el puzle de hoy';

  @override
  String get homeContinueActionButton => 'Continuar';

  @override
  String homeProgressPercent(int percent) {
    return 'Progreso $percent%';
  }

  @override
  String get homeTodayChallengeCardDoneBody =>
      'Terminaste el desafío de hoy. ¡Sigue con tu racha!';

  @override
  String get homeTodayChallengeCardPendingBody =>
      'Un puzle al día: práctica ligera, progreso constante.';

  @override
  String homeTodayChallengeFooterDoneStreak(int days) {
    return 'Desafío de hoy completado · Racha de $days días';
  }

  @override
  String get homeTodayChallengeFooterPending =>
      'Usa el puzle de hoy para construir una racha.';

  @override
  String get homeQuickStartSectionTitle => 'Inicio rápido';

  @override
  String get homeBrowseLevelsTitle => 'Explorar niveles';

  @override
  String get homeStreakTodayDoneLine => 'El desafío de hoy también está listo.';

  @override
  String get homeStreakTodayPendingLine =>
      'Termina el desafío de hoy para extender tu racha.';

  @override
  String get homeBadgeProgressTitle => 'Progreso de insignias';

  @override
  String get homeCatalogPreparingTitle => 'Preparando el catálogo de puzles';

  @override
  String homeCatalogProgressDetail(int generated, int target, int remaining) {
    return '$generated/$target puzles listos · Quedan $remaining';
  }

  @override
  String get levelPickDifficultyTitle => 'Elige la dificultad';

  @override
  String get levelPickDifficultySubtitle =>
      'Elige una dificultad para empezar a jugar.';

  @override
  String get levelPickGameSubtitle => 'Elige un puzle para empezar.';

  @override
  String levelGamesScreenTitle(String levelName) {
    return 'Partidas de $levelName';
  }

  @override
  String get levelLoadingGames => 'Cargando puzles…';

  @override
  String get levelTapToStart => 'Empezar ahora';

  @override
  String get levelClearedBadge => 'Resuelto';

  @override
  String get levelOverviewTitle => 'Resumen del nivel';

  @override
  String get levelPuzzlesSectionTitle => 'Lista de puzles';

  @override
  String get levelProgressLabel => 'Progreso';

  @override
  String get levelNoRecordYet => 'Aún sin registros';

  @override
  String get levelStatusReady => 'Puzle nuevo';

  @override
  String get levelStatusCleared => 'Puzle completado';

  @override
  String levelEmptyCellsLabel(int count) {
    return '$count celdas vacías';
  }

  @override
  String levelPuzzleCountSummary(int count) {
    return '$count puzles';
  }

  @override
  String levelCatalogPreparingShort(int done, int total) {
    return 'Preparando más puzles · $done/$total';
  }

  @override
  String get achievementCollectionAppBarTitle => 'Insignias';

  @override
  String get achievementLoadError => 'No se pudieron cargar las insignias.';

  @override
  String get achievementViewSettings => 'Vista';

  @override
  String get achievementSortLabel => 'Ordenar';

  @override
  String get achievementFilterAll => 'Todas';

  @override
  String get achievementFilterUnlocked => 'Obtenidas';

  @override
  String get achievementFilterLocked => 'En curso';

  @override
  String get achievementSectionAll => 'Todas las insignias';

  @override
  String get achievementSectionUnlocked => 'Insignias obtenidas';

  @override
  String get achievementSectionLocked => 'Insignias en curso';

  @override
  String get achievementEmptyAll => 'No hay insignias que mostrar.';

  @override
  String get achievementEmptyUnlocked =>
      'Aún no has obtenido ninguna insignia.';

  @override
  String get achievementEmptyLocked => 'Has desbloqueado todas las insignias.';

  @override
  String get achievementHeroTitle => 'Logros';

  @override
  String achievementHeroProgress(int unlocked, int total) {
    return '$unlocked / $total desbloqueadas';
  }

  @override
  String get achievementHeroAllUnlocked =>
      'Reuniste todas las insignias. ¡Increíble!';

  @override
  String get achievementHeroKeepGoing =>
      'Sigue jugando para desbloquear más insignias.';

  @override
  String get achievementBadgeFirstClearTitle => 'Primera victoria';

  @override
  String get achievementBadgeFirstClearDesc =>
      'Completa tu primer puzle para comenzar tu viaje en el sudoku.';

  @override
  String get achievementBadgeStreakTitle => 'Racha de 3 días';

  @override
  String get achievementBadgeStreakDesc =>
      'Resuelve puzles tres días seguidos para crear un hábito.';

  @override
  String get achievementBadgeWeeklyTitle => 'Corredor semanal';

  @override
  String get achievementBadgeWeeklyDesc =>
      'Resuelve cinco puzles en los últimos siete días.';

  @override
  String get achievementBadgePerfectTitle => 'Victoria perfecta';

  @override
  String get achievementBadgePerfectDesc =>
      'Termina un puzle sin ningún error.';

  @override
  String get achievementBadgeMasterTitle => 'Primera victoria Maestro';

  @override
  String get achievementBadgeMasterDesc =>
      'Resuelve un puzle de nivel Maestro por primera vez.';

  @override
  String achievementProgressFraction(int current, int max) {
    return '$current/$max';
  }

  @override
  String achievementProgressStreak(int current, int max) {
    return '$current/$max días';
  }

  @override
  String achievementProgressWeekly(int current, int max) {
    return '$current/$max victorias';
  }

  @override
  String get achievementStatusDone => 'Hecho';

  @override
  String get achievementStatusNotMet => 'Pendiente';

  @override
  String get achievementStatusTrying => 'En curso';

  @override
  String achievementTileProgress(String label) {
    return 'Progreso: $label';
  }

  @override
  String achievementTileRarity(String label) {
    return 'Rareza: $label';
  }

  @override
  String get achievementRarityCommon => 'Común';

  @override
  String get achievementRarityRare => 'Raro';

  @override
  String get achievementRarityEpic => 'Épico';

  @override
  String get achievementSortDefault => 'Orden predeterminado';

  @override
  String get achievementSortRarity => 'Por rareza';

  @override
  String get commonSave => 'Guardar';

  @override
  String get settingsDisplaySection => 'Pantalla';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get profileEditorTitle => 'Editar perfil';

  @override
  String get profileEditorRemovePhoto => 'Quitar foto';

  @override
  String get profileEditorNameLabel => 'Nombre';

  @override
  String get profileEditorDefaultProfile => 'Perfil predeterminado';

  @override
  String get profileEditorDefaultProfileDesc =>
      'Empezar con la imagen predeterminada de la app';

  @override
  String get profileEditorPickFromAlbum => 'Elegir del álbum';

  @override
  String get profileEditorPickFromAlbumDesc =>
      'Usar tu propia foto como perfil';

  @override
  String get homeTodayLabel => 'HOY';

  @override
  String get homeTodayPuzzleTitle => 'Un momento tranquilo para concentrarte.';

  @override
  String get homeTodayChallengeStartButton => 'Empezar el reto de hoy';

  @override
  String get homeTodayChallengeResumeButton => 'Continuar el reto de hoy';

  @override
  String get homeTodayChallengeReviewButton => 'Volver a jugar el puzle de hoy';

  @override
  String get homeTodayChallengeLoadError =>
      'No se pudo cargar el puzle de hoy.';

  @override
  String get homeTodayChallengeDateChanged =>
      'Empezó un nuevo día. Se actualizó el reto de hoy.';

  @override
  String get homeFirstStartTitle => 'Empieza tu primer puzle';

  @override
  String get homeNewPuzzleTitle => 'Empieza un puzle nuevo';

  @override
  String get homeChooseLevelBody =>
      'Elige un nivel. Tu progreso se guarda automáticamente.';

  @override
  String get homeChooseLevelButton => 'Elegir nivel';

  @override
  String homeViewAllInProgress(int count) {
    return 'Ver todas las partidas en curso ($count)';
  }

  @override
  String get homeNewGameSectionTitle => 'Partida nueva · elige un nivel';

  @override
  String homeLevelBlankCells(int count) {
    return '$count casillas vacías';
  }

  @override
  String get homeSavedGamesTitle => 'Partidas en curso';

  @override
  String get homeSavedGamesDescription =>
      'Elige una para continuar. Borrar solo elimina el progreso guardado, no tus registros.';

  @override
  String get homeSavedGameDeleteTooltip => 'Borrar progreso guardado';

  @override
  String get homeSavedGameDeleteTitle => '¿Borrar el progreso guardado?';

  @override
  String get homeSavedGameDeleteBody =>
      'Se eliminarán tus entradas y notas de este puzle. Los registros completados se conservan.';

  @override
  String get homeSavedGameDeleteConfirm => 'Borrar';

  @override
  String get homeLoadError => 'No se pudieron cargar tus partidas.';

  @override
  String get homeCatalogFirstTitle => 'Preparando tu primer conjunto de puzles';

  @override
  String get homeCatalogFirstBody =>
      'En tu primer inicio, los puzles de sudoku se guardan en tu dispositivo. Después de esto, la app se abre mucho más rápido.';

  @override
  String get homeCatalogFirstNote =>
      'La preparación continúa en segundo plano, así que puedes seguir explorando de inmediato.';

  @override
  String get homeCatalogFirstContinue => 'Continuar a Inicio';

  @override
  String homeLevelProgressSolved(int cleared, int total) {
    return '$cleared / $total';
  }

  @override
  String get levelFilterAll => 'Todos';

  @override
  String get levelFilterNew => 'Nuevos';

  @override
  String get levelFilterInProgress => 'En curso';

  @override
  String get levelFilterDone => 'Hechos';

  @override
  String levelProgressCardMessage(String levelName) {
    return 'Empieza hoy con puzles de $levelName';
  }

  @override
  String levelProgressCompleted(int total) {
    return '/ $total completados';
  }

  @override
  String get levelRecentBadge => 'Reciente';

  @override
  String get levelStatusInProgress => 'En curso';

  @override
  String get levelNoResults => 'Sin resultados.';

  @override
  String get levelReplayTitle => '¿Volver a jugar este puzle?';

  @override
  String get levelReplayBody =>
      'Tu registro completado se conserva y solo se actualiza si el nuevo resultado es mejor.';

  @override
  String get levelReplayConfirm => 'Repetir';

  @override
  String levelInProgressLimitTitle(int maxCount) {
    return '$maxCount puzles en curso';
  }

  @override
  String levelInProgressLimitBody(int maxCount) {
    return 'Puedes mantener hasta $maxCount puzles a la vez.\nElige uno abajo para continuar.';
  }

  @override
  String get levelInProgressLimitLater => 'Más tarde';

  @override
  String get levelTryAgain => 'Intentar de nuevo';

  @override
  String get levelContinueButton => 'Continuar';

  @override
  String levelStartNextNew(String number) {
    return 'Empezar nuevo puzle · $number';
  }

  @override
  String levelViewInProgress(int count) {
    return 'Ver $count en curso';
  }

  @override
  String get levelNotesInProgress => 'Escribiendo notas';

  @override
  String get levelEmptyInProgress => 'No hay puzles para continuar.';

  @override
  String get levelEmptyCompleted => 'Crea tu primer registro completado.';

  @override
  String get levelEmptyFresh => 'No hay puzles nuevos para empezar.';

  @override
  String get levelAllCompleted =>
      'Has completado todos los puzles de este nivel.';

  @override
  String get levelActionShowNew => 'Ver puzles nuevos';

  @override
  String get levelActionShowInProgress => 'Ver en curso';

  @override
  String get levelActionShowAll => 'Ver todos';

  @override
  String levelBestTime(String time) {
    return 'Mejor tiempo $time';
  }

  @override
  String levelCellSemantics(String number, String status) {
    return 'Puzle $number, $status';
  }

  @override
  String get gameResetDialogTitle => 'Empezar de nuevo';

  @override
  String get gameResetDialogBody =>
      '¿Borrar los números, notas, pistas, errores y el tiempo, y volver al tablero inicial? Tus registros de partidas completadas se conservan.';

  @override
  String get gameResetConfirm => 'Reiniciar';

  @override
  String get gameNumberInputLegend =>
      'Los números pequeños muestran lo que falta; las marcas indican los números completados.';

  @override
  String get dialogSuggestedNextStep => 'Siguiente paso sugerido';

  @override
  String get dialogSetTomorrowReminder => 'Programar recordatorio de mañana';

  @override
  String get dialogTryAnotherLevel => 'Probar otro nivel';

  @override
  String get savedGamesSortRecent => 'Recientes';

  @override
  String get savedGamesSortProgress => 'Progreso';

  @override
  String get savedGamesSortPlayTime => 'Tiempo jugado';

  @override
  String get savedGamesEmpty =>
      'No hay partidas guardadas que coincidan con este filtro.';

  @override
  String get challengeMetricBasisTitle => 'Base de las métricas del desafío';

  @override
  String get challengeMetricBasisWeekly =>
      'Progreso semanal: se basa en las victorias de los últimos 7 días.';

  @override
  String get challengeMetricBasisStreak =>
      'Racha: se basa en los días consecutivos en que completaste el desafío diario.';
}
