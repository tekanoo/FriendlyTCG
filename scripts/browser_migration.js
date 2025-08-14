// Script de migration à exécuter dans la console du navigateur
// pour ajouter participants et updatedAt aux conversations existantes

async function migrateConversations() {
  console.log('🔧 Début de la migration des conversations...');
  
  try {
    // Récupérer toutes les conversations
    const snapshot = await firebase.firestore().collection('conversations').get();
    console.log(`📋 ${snapshot.docs.length} conversations trouvées`);
    
    const batch = firebase.firestore().batch();
    let updated = 0;
    
    snapshot.docs.forEach(doc => {
      const data = doc.data();
      const needsParticipants = !Array.isArray(data.participants);
      const needsUpdatedAt = !data.updatedAt;
      
      if (needsParticipants || needsUpdatedAt) {
        const updates = {};
        
        if (needsParticipants && data.sellerId && data.buyerId) {
          updates.participants = [data.sellerId, data.buyerId];
          console.log(`📝 Ajout participants pour ${doc.id}: [${data.sellerId}, ${data.buyerId}]`);
        }
        
        if (needsUpdatedAt) {
          updates.updatedAt = data.createdAt || firebase.firestore.FieldValue.serverTimestamp();
          console.log(`⏰ Ajout updatedAt pour ${doc.id}`);
        }
        
        if (Object.keys(updates).length > 0) {
          batch.update(doc.ref, updates);
          updated++;
        }
      }
    });
    
    if (updated > 0) {
      await batch.commit();
      console.log(`✅ Migration terminée. ${updated} conversations mises à jour.`);
    } else {
      console.log('✅ Aucune migration nécessaire.');
    }
    
  } catch (error) {
    console.error('❌ Erreur migration:', error);
  }
}

// Pour exécuter: migrateConversations()
