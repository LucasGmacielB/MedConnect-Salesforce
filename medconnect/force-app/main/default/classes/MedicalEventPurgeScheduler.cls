public class MedicalEventPurgeScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        MedicalEventPurgeBatch batch = new MedicalEventPurgeBatch();
        // O tamanho padrão do lote é 200, que geralmente é ideal.
        Database.executeBatch(batch, 200);
    }
}
