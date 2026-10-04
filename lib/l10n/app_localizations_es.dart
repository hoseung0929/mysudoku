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
  String get recordsHeroImageSubtitle => 'Mi historial de resoluciones';

  @override
  String get settingsHeroSubtitle => 'Hazlo a tu manera';

  @override
  String get recordsScreenTitle => 'Registros y estadísticas';

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
  String get dialogPuzzleCompleteTitle => 'Completaste el puzle';

  @override
  String get dialogNewBestMessage => '¡Nuevo mejor registro!';

  @override
  String dialogHintsUsed(int count) {
    return 'Pistas: $count';
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
  String get recordsTrendWindowAvgTime => 'Tiempo prom. (mismo periodo)';

  @override
  String get recordsTrendWindowAvgWrong => 'Errores prom. (mismo periodo)';

  @override
  String get recordsHeroBadgeFlow => 'Ritmo';

  @override
  String get recordsHeroTitle => 'Empieza con la forma suave de tu progreso.';

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
  String get recordsPlayInsightsTitle => 'Actividad de esta semana';

  @override
  String get recordsWeekSubtitle => 'Toca un día para ver tu registro';

  @override
  String get recordsWeeklyGoalLabel => 'Objetivo de la semana';

  @override
  String recordsWeeklyGoalProgress(int done, int goal) {
    String _temp0 = intl.Intl.pluralLogic(
      goal,
      locale: localeName,
      other: '$done / $goal puzles',
      one: '$done / 1 puzle',
    );
    return '$_temp0';
  }

  @override
  String get recordsWeeklyGoalStart => 'Empieza tu primer puzle de la semana';

  @override
  String recordsWeeklyGoalRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Solo $count puzles más para lograr tu objetivo',
      one: 'Solo 1 puzle más para lograr tu objetivo',
    );
    return '$_temp0';
  }

  @override
  String get recordsWeeklyGoalAchieved =>
      'Has logrado el objetivo de la semana';

  @override
  String get gameResultWeeklyGoalAchieved =>
      'Has logrado el objetivo de la semana';

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
  String get recordsMetricAvgTime => 'Tiempo medio';

  @override
  String get recordsMetricAvgWrong => 'Errores medios';

  @override
  String get recordsByLevelTitle => 'Registros por nivel';

  @override
  String get recordsByLevelSubtitle =>
      'Selecciona una dificultad para comparar registros';

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
  String get recordsEmptyAction => 'Empezar un puzle';

  @override
  String get recordsLevelEmpty =>
      'Aún no hay puzles completados en este nivel.';

  @override
  String get recordsRowBestTime => 'Tiempo más rápido';

  @override
  String get recordsAverageBasisNote =>
      'Los promedios se basan en el mejor registro de cada puzle.';

  @override
  String recordsCalendarTitle(int weeks) {
    return 'Actividad de las últimas $weeks semanas';
  }

  @override
  String get recordsCalendarSubtitle =>
      'Consulta los días que completaste y tu frecuencia de juego';

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
      'Actividad de todos los puzles que completaste.';

  @override
  String get recordsActivityTotalClearsLabel => 'Completados en total';

  @override
  String get recordsActivityCurrentStreakLabel => 'Racha actual';

  @override
  String get recordsActivityBestStreakLabel => 'Mayor racha';

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
      'Mira de un vistazo tus últimos 7 días de sudoku.';

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
  String get challengeTabHeroHeadline =>
      'El puzle de hoy y tu ritmo semanal, en una sola vista tranquila.';

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
  String get homeChallengeStartButton => 'Empezar desafío';

  @override
  String get homeChallengeReplayButton => 'Jugar de nuevo';

  @override
  String get homeChallengeNotStarted => 'Aún sin empezar';

  @override
  String get homeChallengeFirstLine =>
      'Tu primer desafío empieza en Principiante';

  @override
  String homeChallengePromotedLine(String level) {
    return '¿Probamos $level hoy?';
  }

  @override
  String homeChallengeProgress(int percent) {
    return '$percent% completado';
  }

  @override
  String get homeChallengeDoneLine => '¡Desafío de hoy completado!';

  @override
  String homeChallengeStreak(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Racha de desafíos: $days días',
      one: 'Racha de desafíos: 1 día',
    );
    return '$_temp0';
  }

  @override
  String get homeChallengeLoadErrorTitle =>
      'No se pudo cargar el desafío de hoy';

  @override
  String get homeChallengeLoadErrorBody => 'Inténtalo de nuevo en un momento.';

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
  String levelPuzzleListTitle(int count) {
    return 'Rompecabezas · $count';
  }

  @override
  String get levelRecentBadge => 'Reciente';

  @override
  String get levelStatusInProgress => 'En curso';

  @override
  String get levelNoResults => 'Sin resultados.';

  @override
  String levelReplayTitle(int number) {
    return '¿Volver a jugar el puzle $number?';
  }

  @override
  String get levelReplayBody =>
      'Tu registro completado se mantiene. Si lo terminas con un mejor resultado, solo se actualiza tu mejor registro.';

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
  String get levelStartNewButton => 'Empezar puzle';

  @override
  String levelPuzzleNumber(int number) {
    return 'Puzle $number';
  }

  @override
  String levelCompletedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count completados',
      one: '1 completado',
    );
    return '$_temp0';
  }

  @override
  String get levelCardFirstSub => '¿Empezamos por el primer puzle?';

  @override
  String get levelCardNextSub => 'Empieza el siguiente puzle';

  @override
  String levelCardAllDoneTitle(String levelName) {
    return 'Completaste todos los puzles de $levelName';
  }

  @override
  String get levelCardAllDoneSub => 'Vuelve a resolver los puzles completados';

  @override
  String get levelCardViewCompleted => 'Ver puzles completados';

  @override
  String levelViewInProgress(int count) {
    return 'Ver $count en curso';
  }

  @override
  String get levelNotesInProgress => 'Escribiendo notas';

  @override
  String get levelEmptyInProgress =>
      'Todavía no tienes un puzle para continuar.';

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
  String get savedGamesDeleteFailed =>
      'No se pudo eliminar este puzzle. Inténtalo de nuevo.';

  @override
  String get recordsMyRecordTitle => 'Hasta ahora';

  @override
  String recordsSummaryHeroSentence(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Has completado $count puzles',
      one: 'Has completado 1 puzle',
    );
    return '$_temp0';
  }

  @override
  String get recordsSummaryHeroFirst => 'Completaste tu primer puzle';

  @override
  String recordsSummaryHeroMilestone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¡Has llegado a $count puzles! Qué constancia',
      one: '¡Has llegado a 1 puzle! Qué constancia',
    );
    return '$_temp0';
  }

  @override
  String recordsSummaryHeroGrowing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ya has resuelto $count puzles',
      one: 'Ya has resuelto 1 puzle',
    );
    return '$_temp0';
  }

  @override
  String recordsSummaryHeroStacked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tu registro suma $count puzles',
      one: 'Tu registro suma 1 puzle',
    );
    return '$_temp0';
  }

  @override
  String get recordsLevelRingsTitle => 'Progreso por nivel';

  @override
  String recordsLevelRingSemantics(String level, int cleared, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      cleared,
      locale: localeName,
      other: '$cleared de $total completados',
      one: '1 de $total completado',
    );
    return '$level, $_temp0';
  }

  @override
  String get recordsSummaryAllPerfect => 'Todos resueltos sin errores';

  @override
  String recordsSummaryPartialPerfect(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de ellos sin errores',
      one: '1 de ellos sin errores',
    );
    return '$_temp0';
  }

  @override
  String recordsSummaryStreakPlaying(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Llevas $days días seguidos jugando',
      one: 'Jugaste 1 día seguido',
    );
    return '$_temp0';
  }

  @override
  String recordsSummaryPlayDays(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días jugados',
      one: '1 día jugado',
    );
    return '$_temp0';
  }

  @override
  String get recordsSummaryEmptyTitle => '¿Creamos tu primer registro?';

  @override
  String get recordsSummaryEmptyBody =>
      'Cuando completes un puzle, tus registros se acumularán aquí';

  @override
  String get challengeTodayEyebrow => 'Hoy';

  @override
  String get gamePausedTitle => 'En pausa';

  @override
  String get gamePausedBody => 'El tiempo está detenido y el tablero, oculto.';

  @override
  String homeStreakChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String homeStreakActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Llevas $count días seguidos completando puzles',
      one: 'Completaste un puzle hoy',
    );
    return '$_temp0';
  }

  @override
  String homeStreakAtRisk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Racha de $count días. Completa un puzle hoy para mantenerla.',
      one: 'Racha de 1 día. Completa un puzle hoy para mantenerla.',
    );
    return '$_temp0';
  }

  @override
  String get hintStepLookTitle => 'Pista · Dónde mirar';

  @override
  String get hintLookCell =>
      'Mira la fila, la columna y el bloque de la casilla resaltada.';

  @override
  String hintLookBox(int value) {
    return 'Busca dónde va el $value en el bloque resaltado.';
  }

  @override
  String hintLookRow(int value) {
    return 'Busca dónde va el $value en la fila resaltada.';
  }

  @override
  String hintLookCol(int value) {
    return 'Busca dónde va el $value en la columna resaltada.';
  }

  @override
  String get hintMovedFromSelection =>
      'Hay una casilla más fácil para resolver primero.';

  @override
  String get hintTechniqueNakedSingle => 'Candidato único';

  @override
  String get hintTechniqueHiddenSingle => 'Único oculto';

  @override
  String get hintTechniqueReveal => 'Respuesta';

  @override
  String hintExplainNakedSingle(int value) {
    return 'La fila, la columna y el bloque de esta casilla ya tienen los otros ocho números, así que solo cabe el $value.';
  }

  @override
  String hintExplainHiddenSingleBox(int value) {
    return 'En este bloque, el $value solo puede ir aquí. Las demás casillas vacías comparten fila o columna con un $value resaltado.';
  }

  @override
  String hintExplainHiddenSingleRow(int value) {
    return 'En esta fila, el $value solo puede ir aquí. Las demás casillas vacías comparten columna o bloque con un $value resaltado.';
  }

  @override
  String hintExplainHiddenSingleCol(int value) {
    return 'En esta columna, el $value solo puede ir aquí. Las demás casillas vacías comparten fila o bloque con un $value resaltado.';
  }

  @override
  String get hintExplainReveal =>
      'Esta casilla necesita una técnica más avanzada. Puedes poner la respuesta con el botón de abajo.';

  @override
  String get hintNextStep => 'Más detalles';

  @override
  String get hintFillAnswer => 'Poner respuesta';

  @override
  String get hintClose => 'Cerrar pista';

  @override
  String get notificationOptInTitle => '¿Quieres un recordatorio diario?';

  @override
  String get notificationOptInBody =>
      'Si a las 8 de la tarde aún no has resuelto un puzle, te lo recordaremos. Puedes desactivarlo cuando quieras en Ajustes.';

  @override
  String get notificationOptInAccept => 'Activar recordatorios';

  @override
  String get notificationOptInLater => 'Ahora no';

  @override
  String get notificationOptInDenied =>
      'No se permiten las notificaciones. Actívalas en los ajustes del dispositivo y luego enciende los recordatorios en Ajustes.';

  @override
  String get notificationSetupFailed =>
      'No pudimos configurar los recordatorios. Inténtalo de nuevo más tarde en Ajustes.';

  @override
  String get beginnerTutorialPromptTitle => '¿Eres nuevo en el sudoku?';

  @override
  String get beginnerTutorialPromptBody =>
      'Prueba una práctica corta para aprender las reglas básicas y los controles.';

  @override
  String get beginnerTutorialStart => 'Empezar práctica';

  @override
  String get beginnerTutorialSkip => 'Omitir';

  @override
  String beginnerTutorialStepIndicator(int current, int total) {
    return '$current / $total';
  }

  @override
  String get beginnerTutorialPracticeTitle => 'Puzle de práctica';

  @override
  String get beginnerTutorialStepRulesTitle => 'Reglas básicas';

  @override
  String get beginnerTutorialStepRulesBody =>
      'Cada fila, columna y cuadro de 3×3 contiene los números del 1 al 9 una sola vez.';

  @override
  String get beginnerTutorialRuleRow => 'Fila';

  @override
  String get beginnerTutorialRuleColumn => 'Columna';

  @override
  String get beginnerTutorialRuleBox => 'Cuadro 3×3';

  @override
  String get beginnerTutorialStepInputTitle => 'Introduce un número';

  @override
  String get beginnerTutorialStepInputBody =>
      'Toca la casilla resaltada y elige el número que encaja.';

  @override
  String get beginnerTutorialStepInputWrongHint =>
      'No puedes poner un número que ya está en la misma fila, columna o cuadro de 3×3.';

  @override
  String get beginnerTutorialStepMemoTitle => 'Anota candidatos';

  @override
  String get beginnerTutorialStepMemoAddBody =>
      'Activa las notas y anota números candidatos en la casilla resaltada.';

  @override
  String get beginnerTutorialStepMemoEraseBody =>
      'Toca el mismo número otra vez para borrar una nota.';

  @override
  String get beginnerTutorialStepHintTitle => 'Usa una pista';

  @override
  String get beginnerTutorialStepHintBody =>
      'Si te atascas, toca Pista para ver qué casilla mirar y por qué.';

  @override
  String get beginnerTutorialStepDoneTitle => '¡Listo!';

  @override
  String get beginnerTutorialStepDoneBody =>
      'Ya sabes introducir números, usar notas y pedir pistas.';

  @override
  String get beginnerTutorialFirstPuzzleButton => 'Empezar mi primer puzzle';

  @override
  String get beginnerTutorialNextButton => 'Siguiente';

  @override
  String get beginnerTutorialCloseButton => 'Listo';

  @override
  String get settingsHowToPlayTitle => 'Cómo jugar';

  @override
  String get settingsHowToPlaySubtitle => 'Repetir el tutorial guiado';

  @override
  String get autoNotesConfirmTitle => '¿Volver a rellenar todas las notas?';

  @override
  String get autoNotesConfirmBody =>
      'Esto reemplaza las notas de cada casilla vacía con los candidatos actuales. Los candidatos que borraste a mano podrían reaparecer.';

  @override
  String get autoNotesConfirmApply => 'Rellenar notas';

  @override
  String get autoNotesContradictionMessage =>
      'Algunas casillas se quedaron sin ningún número posible, así que no se rellenaron las notas. Revisa tus entradas e inténtalo de nuevo.';

  @override
  String get autoNotesTipMessage =>
      'Consejo: mantén pulsado Notas para rellenar todos los candidatos a la vez.';

  @override
  String get gameNumberLockTipMessage =>
      'Mantén pulsado un número para fijarlo y rellenarlo en varias casillas rápidamente.';

  @override
  String gameNumberButtonLockedSemantics(int number) {
    return '$number, fijado, mantén pulsado para soltar';
  }

  @override
  String get gameNumberButtonLockHint => 'Mantén pulsado para fijar';

  @override
  String get gameMemoLongPressHint =>
      'Toca para alternar Notas. Mantén pulsado para rellenar candidatos automáticamente.';

  @override
  String get homeGreetingMorning => 'Empieza con un puzle ligero.';

  @override
  String get homeGreetingAfternoon => 'Es un buen momento para concentrarte.';

  @override
  String get homeGreetingEvening => 'Relájate con un puzle tranquilo.';

  @override
  String get levelNoPuzzlesAvailable =>
      'No hay puzles disponibles para este nivel.';

  @override
  String get levelLastPlayedToday => 'Hoy';

  @override
  String get levelLastPlayedYesterday => 'Ayer';

  @override
  String levelLastPlayedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return 'Hace $_temp0';
  }
}
