import '../models/lab_schedule.dart';

class DefaultSchedules {
  static Map<String, List<LabSchedule>> get all => {
        'LT_MAP': ltSchedules,
        'UD2': ud2Schedules,
      };

  static List<LabSchedule> get ltSchedules => [
        LabSchedule(labName: 'Electrónica', entries: [
          ScheduleEntry(day: 'Lunes', startTime: '08:00', endTime: '08:50', subject: 'CIRCUITOS ELÉCTRICOS', group: '2A IMT', teacher: 'MIGUEL ARREGUIN JUÁREZ'),
          ScheduleEntry(day: 'Lunes', startTime: '08:50', endTime: '09:40', subject: 'CIRCUITOS ELÉCTRICOS', group: '2A IMT', teacher: 'MIGUEL ARREGUIN JUÁREZ'),
          ScheduleEntry(day: 'Jueves', startTime: '08:00', endTime: '08:50', subject: 'CIRCUITOS ELÉCTRICOS', group: '2A IMT', teacher: 'MIGUEL ARREGUIN JUÁREZ'),
          ScheduleEntry(day: 'Jueves', startTime: '10:30', endTime: '11:20', subject: 'COMUNICACIONES MÓVILES', group: '8A ITR', teacher: 'JUAN ISRAEL YAÑEZ VARGAS'),
          ScheduleEntry(day: 'Jueves', startTime: '11:20', endTime: '12:10', subject: 'COMUNICACIONES MÓVILES', group: '8A ITR', teacher: 'JUAN ISRAEL YAÑEZ VARGAS'),
          ScheduleEntry(day: 'Viernes', startTime: '08:00', endTime: '08:50', subject: 'CIRCUITOS ELÉCTRICOS', group: '2A IMT', teacher: 'MIGUEL ARREGUIN JUÁREZ'),
        ]),
        LabSchedule(labName: 'Telemática', entries: [
          ScheduleEntry(day: 'Lunes', startTime: '08:50', endTime: '09:40', subject: 'PROYECTO INTEGRADOR', group: '5A ITR', teacher: 'FABIOLA PIÑA MENDOZA'),
          ScheduleEntry(day: 'Lunes', startTime: '09:40', endTime: '10:30', subject: 'GOBIERNO CORPORATIVO', group: '8A ITR', teacher: 'FABIOLA PIÑA MENDOZA'),
          ScheduleEntry(day: 'Martes', startTime: '08:00', endTime: '08:50', subject: 'SEGURIDAD EN REDES', group: '5A ITR', teacher: 'ERICK MONTECILLO'),
          ScheduleEntry(day: 'Martes', startTime: '08:50', endTime: '09:40', subject: 'PROYECTO INTEGRADOR', group: '5A ITR', teacher: 'FABIOLA PIÑA'),
          ScheduleEntry(day: 'Martes', startTime: '09:40', endTime: '10:30', subject: 'SEGURIDAD EN REDES Y TELECOMUNICACIONES', group: '8A IRT', teacher: 'ERICK MONTECILLO'),
          ScheduleEntry(day: 'Martes', startTime: '10:30', endTime: '11:20', subject: 'SEGURIDAD EN REDES Y TELECOMUNICACIONES', group: '8A IRT', teacher: 'ERICK MONTECILLO'),
          ScheduleEntry(day: 'Miércoles', startTime: '08:00', endTime: '08:50', subject: 'SEGURIDAD EN REDES', group: '5A ITR', teacher: 'ERICK MONTECILLO'),
          ScheduleEntry(day: 'Miércoles', startTime: '08:50', endTime: '09:40', subject: 'PROYECTO INTEGRADOR', group: '5A ITR', teacher: 'FABIOLA PIÑA'),
          ScheduleEntry(day: 'Miércoles', startTime: '09:40', endTime: '10:30', subject: 'SEGURIDAD EN REDES Y TELECOMUNICACIONES', group: '8A IRT', teacher: 'ERICK MONTECILLO'),
          ScheduleEntry(day: 'Miércoles', startTime: '10:30', endTime: '11:20', subject: 'SEGURIDAD EN REDES Y TELECOMUNICACIONES', group: '8A IRT', teacher: 'ERICK MONTECILLO'),
          ScheduleEntry(day: 'Miércoles', startTime: '11:20', endTime: '12:10', subject: 'CÓMPUTO EN LA NUBE', group: '5A ITR', teacher: 'MIGUEL ARREGUIN'),
          ScheduleEntry(day: 'Miércoles', startTime: '12:10', endTime: '13:00', subject: 'SISTEMAS OPERATIVOS', group: '2A ITR', teacher: 'MIGUEL ARREGUIN'),
          ScheduleEntry(day: 'Jueves', startTime: '08:50', endTime: '09:40', subject: 'PROYECTO INTEGRADOR', group: '5A ITR', teacher: 'FABIOLA PIÑA'),
          ScheduleEntry(day: 'Jueves', startTime: '09:40', endTime: '10:30', subject: 'GOBIERNO CORPORATIVO', group: '8A ITR', teacher: 'FABIOLA PIÑA'),
          ScheduleEntry(day: 'Viernes', startTime: '08:50', endTime: '09:40', subject: 'PROYECTO INTEGRADOR', group: '5A ITR', teacher: 'FABIOLA PIÑA'),
          ScheduleEntry(day: 'Viernes', startTime: '09:40', endTime: '10:30', subject: 'GOBIERNO CORPORATIVO', group: '8A ITR', teacher: 'FABIOLA PIÑA'),
          ScheduleEntry(day: 'Viernes', startTime: '11:20', endTime: '12:10', subject: 'CÓMPUTO EN LA NUBE', group: '5A ITR', teacher: 'MIGUEL ARREGUIN'),
          ScheduleEntry(day: 'Viernes', startTime: '12:10', endTime: '13:00', subject: 'SISTEMAS OPERATIVOS', group: '2A ITR', teacher: 'MIGUEL ARREGUIN'),
        ]),
        LabSchedule(labName: 'Redes', entries: [
          ScheduleEntry(day: 'Lunes', startTime: '08:00', endTime: '08:50', subject: 'CONMUTACIÓN Y ENRUTAMIENTO', group: '2A ITR', teacher: 'ERICK MONTECILLO'),
          ScheduleEntry(day: 'Lunes', startTime: '08:50', endTime: '09:40', subject: 'CONMUTACIÓN Y ENRUTAMIENTO', group: '2A ITR', teacher: 'ERICK MONTECILLO'),
          ScheduleEntry(day: 'Lunes', startTime: '10:30', endTime: '11:20', subject: 'SEGURIDAD EN REDES Y TELECOMUNICACIONES', group: '8A IRT', teacher: 'ERICK MONTECILLO'),
          ScheduleEntry(day: 'Lunes', startTime: '11:20', endTime: '12:10', subject: 'SEGURIDAD EN REDES Y TELECOMUNICACIONES', group: '8A IRT', teacher: 'ERICK MONTECILLO'),
          ScheduleEntry(day: 'Martes', startTime: '08:50', endTime: '09:40', subject: 'CONMUTACIÓN Y ENRUTAMIENTO', group: '2A ITR', teacher: 'ERICK MONTECILLO'),
          ScheduleEntry(day: 'Martes', startTime: '13:00', endTime: '13:50', subject: 'CONEXIÓN DE REDES WAN', group: '5A ITR', teacher: 'JUAN GALLEGOS'),
          ScheduleEntry(day: 'Martes', startTime: '13:50', endTime: '14:40', subject: 'CONEXIÓN DE REDES WAN', group: '5A ITR', teacher: 'JUAN GALLEGOS'),
          ScheduleEntry(day: 'Miércoles', startTime: '13:00', endTime: '13:50', subject: 'CONEXIÓN DE REDES WAN', group: '5A ITR', teacher: 'JUAN GALLEGOS'),
          ScheduleEntry(day: 'Miércoles', startTime: '13:50', endTime: '14:40', subject: 'CONEXIÓN DE REDES WAN', group: '5A ITR', teacher: 'JUAN GALLEGOS'),
          ScheduleEntry(day: 'Jueves', startTime: '08:00', endTime: '08:50', subject: 'SEGURIDAD EN REDES', group: '5A ITR', teacher: 'ERICK MONTECILLO'),
          ScheduleEntry(day: 'Viernes', startTime: '08:00', endTime: '08:50', subject: 'SEGURIDAD EN REDES', group: '5A ITR', teacher: 'ERICK MONTECILLO'),
          ScheduleEntry(day: 'Viernes', startTime: '08:50', endTime: '09:40', subject: 'SEGURIDAD EN REDES', group: '5A ITR', teacher: 'ERICK MONTECILLO'),
        ]),
      ];

  static List<LabSchedule> get ud2Schedules => [
        LabSchedule(
          labName: 'Laboratorio de Móviles',
          entries: [
            ScheduleEntry(day: 'Lunes', startTime: '09:40', endTime: '10:30', subject: 'PROGRAMACIÓN ESTRUCTURADA', group: '2A ITR', teacher: 'DIEGO ANGEL VILLAFUERTE LUCIO'),
            ScheduleEntry(day: 'Lunes', startTime: '11:20', endTime: '12:10', subject: 'CÓMPUTO EN LA NUBE', group: '5A ITR', teacher: 'MIGUEL ARREGUIN JUÁREZ'),
            ScheduleEntry(day: 'Lunes', startTime: '12:10', endTime: '13:00', subject: 'SISTEMAS OPERATIVOS', group: '2A ITR', teacher: 'MIGUEL ARREGUIN JUÁREZ'),
            ScheduleEntry(day: 'Lunes', startTime: '13:50', endTime: '14:40', subject: 'TECNOLOGÍAS DE VIRTUALIZACIÓN', group: '8A IRT', teacher: 'MIGUEL ARREGUIN JUÁREZ'),
            ScheduleEntry(day: 'Lunes', startTime: '14:40', endTime: '15:30', subject: 'TECNOLOGÍAS DE VIRTUALIZACIÓN', group: '8A IRT', teacher: 'MIGUEL ARREGUIN JUÁREZ'),
            ScheduleEntry(day: 'Martes', startTime: '09:40', endTime: '10:30', subject: 'PROGRAMACIÓN ESTRUCTURADA', group: '2A ITR', teacher: 'DIEGO ANGEL VILLAFUERTE LUCIO'),
            ScheduleEntry(day: 'Martes', startTime: '11:20', endTime: '12:10', subject: 'CÓMPUTO EN LA NUBE', group: '5A ITR', teacher: 'MIGUEL ARREGUIN JUÁREZ'),
            ScheduleEntry(day: 'Martes', startTime: '12:10', endTime: '13:00', subject: 'SISTEMAS OPERATIVOS', group: '2A ITR', teacher: 'MIGUEL ARREGUIN JUÁREZ'),
            ScheduleEntry(day: 'Miércoles', startTime: '08:50', endTime: '09:40', subject: 'CONMUTACIÓN Y ENRUTAMIENTO DE REDES', group: '2A ITR', teacher: 'ERICK MONTECILLO'),
            ScheduleEntry(day: 'Miércoles', startTime: '09:40', endTime: '10:30', subject: 'PROGRAMACIÓN ESTRUCTURADA', group: '2A ITR', teacher: 'DIEGO ANGEL VILLAFUERTE LUCIO'),
            ScheduleEntry(day: 'Miércoles', startTime: '11:20', endTime: '12:10', subject: 'PROCESAMIENTO DE SEÑALES', group: '8A IRT', teacher: 'JOEL QUINTANILLA DOMÍNGUEZ'),
            ScheduleEntry(day: 'Miércoles', startTime: '12:10', endTime: '13:00', subject: 'PROCESAMIENTO DE SEÑALES', group: '8A IRT', teacher: 'JOEL QUINTANILLA DOMÍNGUEZ'),
            ScheduleEntry(day: 'Jueves', startTime: '08:50', endTime: '09:40', subject: 'CONMUTACIÓN Y ENRUTAMIENTO DE REDES', group: '2A ITR', teacher: 'ERICK MONTECILLO'),
            ScheduleEntry(day: 'Jueves', startTime: '09:40', endTime: '10:30', subject: 'PROGRAMACIÓN ESTRUCTURADA', group: '2A ITR', teacher: 'DIEGO ANGEL VILLAFUERTE LUCIO'),
            ScheduleEntry(day: 'Jueves', startTime: '11:20', endTime: '12:10', subject: 'CÓMPUTO EN LA NUBE', group: '5A ITR', teacher: 'MIGUEL ARREGUIN JUÁREZ'),
            ScheduleEntry(day: 'Jueves', startTime: '12:10', endTime: '13:00', subject: 'SISTEMAS OPERATIVOS', group: '2A ITR', teacher: 'MIGUEL ARREGUIN JUÁREZ'),
            ScheduleEntry(day: 'Jueves', startTime: '13:50', endTime: '14:40', subject: 'TECNOLOGÍAS DE VIRTUALIZACIÓN', group: '8A IRT', teacher: 'MIGUEL ARREGUIN JUÁREZ'),
            ScheduleEntry(day: 'Viernes', startTime: '09:40', endTime: '10:30', subject: 'PROGRAMACIÓN ESTRUCTURADA', group: '2A ITR', teacher: 'DIEGO ANGEL VILLAFUERTE LUCIO'),
            ScheduleEntry(day: 'Viernes', startTime: '10:30', endTime: '11:20', subject: 'PROCESAMIENTO DE SEÑALES', group: '8A IRT', teacher: 'JOEL QUINTANILLA DOMÍNGUEZ'),
            ScheduleEntry(day: 'Viernes', startTime: '11:20', endTime: '12:10', subject: 'PROCESAMIENTO DE SEÑALES', group: '8A IRT', teacher: 'JOEL QUINTANILLA DOMÍNGUEZ'),
            ScheduleEntry(day: 'Viernes', startTime: '12:10', endTime: '13:00', subject: 'CÁLCULO DIFERENCIAL', group: '2A ITR', teacher: 'JUAN ISRAEL YAÑEZ VARGAS'),
            ScheduleEntry(day: 'Viernes', startTime: '13:00', endTime: '13:50', subject: 'CÁLCULO DIFERENCIAL', group: '2A ITR', teacher: 'JUAN ISRAEL YAÑEZ VARGAS'),
            ScheduleEntry(day: 'Viernes', startTime: '13:50', endTime: '14:40', subject: 'TECNOLOGÍAS DE VIRTUALIZACIÓN', group: '8A IRT', teacher: 'MIGUEL ARREGUIN JUÁREZ'),
            ScheduleEntry(day: 'Viernes', startTime: '15:30', endTime: '16:20', subject: 'CÁLCULO DIFERENCIAL', group: '2A ITR', teacher: 'JUAN ISRAEL YAÑEZ VARGAS'),
          ],
        ),
      ];
}
