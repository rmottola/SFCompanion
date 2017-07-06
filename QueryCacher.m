/*
   Project: SFCompanion

   Copyright (C) 2014-2016 Riccardo Mottola

   Author: Riccardo Mottola

   Created: 2014-07-11 14:14:35 +0000 by multix

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
 
   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
 
   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc.,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

#import <DataBasinKit/DBSoap.h>
#import <DataBasinKit/DBSObject.h>

#import "QueryCacher.h"

static NSString *tkBatchBackground = @"Select Id From Case Where IsClosed = false and ((RecordTypeId = '01220000000TwxuAAC' and Fase__c ='DC090' )  OR (Invoca_callout_delayed__c = true) OR (RecordTypeId IN ('012200000000xjgAAA','01220000000Twy6AAC') and ( (Fase__c = 'DI150' and Cod_cliente__c != null and (NOT Cod_cliente__c LIKE 'ASS%') ))) OR (  ((RecordTypeId = '012200000000ydSAAQ'  and Fase__c = 'DI150')or ( RecordTypeId = '01220000000Twy0AAC' and Fase__c = 'DI150')) and Cod_cliente__c != null and (NOT Cod_cliente__c LIKE 'ASS%')) OR (( RecordTypeId IN('012200000000xjmAAA','01220000000AMsz')  and Fase__c = 'DI150' )  and Cod_cliente__c != null and (NOT Cod_cliente__c LIKE 'ASS%')) OR ( RecordTypeId = '01220000000AMsu'   and Fase__c IN('IR210','DI260')  and Cod_cliente__c != null and (NOT Cod_cliente__c LIKE 'ASS%')) OR (RecordTypeId = '01220000000AMsuAAG' and (AccountId = null or POD_PDR__c = null) and Fase__c ='IR010' and CreatedDate < TODAY ) OR (RecordTypeId = '01220000000TwxqAAC' and Sottocategoria_causale__c ='Callback' ) OR (RecordTypeId = '01220000000TwxqAAC' and Sottocategoria_causale__c ='Pagamento con carta di credito' and CreatedDate < TODAY))";

static NSString *tkBatchPriority = @"Select id From Case Where IsClosed = false and ((RecordTypeId = '01220000000TwxtAAC' and Fase__c IN ('AN020','DC010','WL100')  and data_check_callout__c = null and Pratica__r.Pratica_padre__c != null)  OR (RecordTypeId = '012200000000xjnAAA' and invoca_callout_old__c > 0 and Status != 'Sospeso'  and data_check_callout__c = null )  OR (RecordTypeId = '01220000000AGg4' and invoca_callout_2_old__c > 0 and data_check_callout__c = null) OR (RecordTypeId = '01220000000TwxlAAC' and invoca_callout_gas_old__c >0 and Tipo_lavoro__c = 'Contratto non richiesto' and data_check_callout__c = null) OR (RecordTypeId = '012200000001BxsAAE' and Reclamo_Data_Invio_CallOut__c = null and Fase__c = 'RL030' and invoca_callout_tiqv_old__c = 1 ) )";

static NSString *pratBatchPriority = @"select id from pratica__c where ((RecordTypeId IN ('01220000000TwwIAAS') and ((  Callout_Switch_Copia__c = 1 and Stato_pratica__c != 'Chiusa')  or (C_Processo__c != 'Ripristino' and Stato_pratica__c = 'Da verificare' and Data_stampa_lettera__c = null  and Causale_rettifica__c = null and Data_verifica_contratto__c = null and Data_inoltro__c = null)  or (C_Processo__c = 'Ripristino' and Stato_pratica__c = 'Verificata' and Data_stampa_lettera__c = null  and Causale_rettifica__c = null and Data_verifica_contratto__c != null and Data_inoltro__c = null) ))) OR ((RecordTypeId = '01220000000TwwB' and CS_Origin__c = 'Web' and C_Data_stampa__c = null)) OR ((RecordTypeId = '01220000000TwwNAAS' AND CS_Origin__c = 'Web' AND Stampa_contratto__c = true))";

static NSString *pratBatchBackground = @"Select Id From Pratica__c Where (Codice_stato_documentale__c IN ('D010', 'D020', 'D030', 'D040', 'D050', 'D060', 'D070') AND RecordTypeId IN ('01220000000TwwNAAS', '01220000000TwwFAAS', '01220000000Tww8AAC', '01220000000TwwIAAS', '01220000000AGgi', '01220000000AKpm')) AND (( (RecordTypeId IN ('01220000000TwwNAAS','01220000000TwwFAAS') or (RecordTypeId='01220000000Tww8AAC' and Motivazione__c = 'A40')  OR (RecordTypeId ='01220000000TwwIAAS' and (Modalita_di_stipula__c = 'Teleselling' or (Modalita_di_stipula__c = 'WEB' and CS_Origin__c ='Web')))  OR ( (C_Processo__c = 'Stand alone') AND C_Allegato_Necessario__c = 'Desiderato' AND RecordTypeID ='01220000000AGgi')) and (((C_Data_invio_doc_cliente__c != null and C_Data_ricezione_doc__c = null) AND ((C_Data_invio_doc_cliente__c< LAST_N_DAYS:20 and C_Data_sollecito__c = null and Codice_stato_documentale__c IN ('D010', 'D020', 'D030', 'D040', 'D050', 'D060'))or  (C_Data_Sollecito__c< LAST_N_DAYS:10 and C_Data_sollecito__c != null and Codice_stato_documentale__c = 'D040')) ) or  (C_Data_invio_integrazione_cliente__c< LAST_N_DAYS:10 and C_Data_invio_integrazione_cliente__c != null and C_Data_ricezione_integrazione__c = null and Codice_stato_documentale__c = 'D030')or  (Data_SMS__c< LAST_N_DAYS:15 and Data_SMS__c != null and Codice_stato_documentale__c = 'D060'))) OR ((C_Allegato_Necessario__c = 'Necessario' AND RecordTypeID ='01220000000AGgi' and C_Tipologia__c IN ('Attivazione', 'Variazione') and C_Data_invio_doc_cliente__c != null and C_Data_ricezione_doc__c = null and (( Codice_stato_documentale__c = 'D010' and  Data_SMS__c = null and C_Data_invio_doc_cliente__c < LAST_N_DAYS:2) or (Tipologia_SMS__c!='SMS 2' and C_Data_invio_doc_cliente__c < LAST_N_DAYS:5) or ( C_Data_invio_doc_cliente__c < LAST_N_DAYS:10)))) OR ((C_Allegato_Necessario__c = 'Necessario' AND C_Tipo_Lavoro__c = 'Cambio Opzione' AND RecordTypeID ='01220000000AKpm' and C_Data_invio_doc_cliente__c != null and C_Data_ricezione_doc__c = null and (( Codice_stato_documentale__c = 'D010' and  Data_SMS__c = null and C_Data_invio_doc_cliente__c < LAST_N_DAYS:5) or ( C_Data_invio_doc_cliente__c < LAST_N_DAYS:30)))) OR ((C_Allegato_Necessario__c = 'Desiderato' AND C_Tipo_Lavoro__c = 'Cambio Opzione' AND RecordTypeID ='01220000000AKpm' and C_Data_invio_doc_cliente__c != null and C_Data_ricezione_doc__c = null and((C_Data_Sollecito__c< LAST_N_DAYS:10 and C_Data_invio_doc_cliente__c != null and C_Data_sollecito__c != null and C_Data_ricezione_doc__c = null and Codice_stato_documentale__c = 'D040')or  (C_Data_invio_integrazione_cliente__c< LAST_N_DAYS:10 and C_Data_invio_integrazione_cliente__c != null and C_Data_ricezione_integrazione__c = null and Codice_stato_documentale__c = 'D030')or  (Data_SMS__c< LAST_N_DAYS:15 and Data_SMS__c != null and Codice_stato_documentale__c = 'D060')or (C_Data_invio_doc_cliente__c< LAST_N_DAYS:20 and C_Data_invio_doc_cliente__c != null and C_Data_sollecito__c = null and C_Data_ricezione_doc__c = null and Codice_stato_documentale__c IN ('D010', 'D020', 'D030', 'D040', 'D050', 'D060'))))))";

static NSString *rinnoviAssenso = @"select Id, Fase__c, Campagna__c, Offerta__r.CampaignId, Campagna__r.Fase__c, Offerta__r.Campaign.Tacito_rinnovo__c, Nuova_fornitura__r.Stato_numerico_fornitura__c from Case where RecordTypeId = '01220000000TwxrAAC' and ((Fase__c = 'IL020' and Offerta__r.CampaignId != null and Campagna__r.Fase__c in ('IL020', 'IR090') and Offerta__r.Campaign.Tacito_rinnovo__c <= TODAY) or (Fase__c in ('IR010', 'IL020', 'IR090') and Nuova_fornitura__r.Stato_numerico_fornitura__c = 0))";


@implementation QueryCacher

- (id) init
{
  if ((self = [super init]))
    {
      [NSBundle loadNibNamed:@"QueryCacher" owner:self];
      [querySelector removeAllItems];
      [querySelector addItemWithTitle:@"Ticket Batch Background"];
      [querySelector addItemWithTitle:@"Ticket Batch Priority"];
      [querySelector addItemWithTitle:@"Pratica Batch Priority"];
      [querySelector addItemWithTitle:@"Pratica Batch Background"];
      [querySelector addItemWithTitle:@"Rinnovi Assenso"];
    }
  return self;
}

- (void)show:(id)sender
{
  [win makeKeyAndOrderFront:nil];
}

- (IBAction)execute:(id)sender
{
  NSString *query;
  NSMutableArray *resArray;
  BOOL wentTimeOut;
  NSInteger iteration;
  BOOL done;
  
  switch ([querySelector indexOfSelectedItem])
    {
      case 0:
        query = tkBatchBackground;
        break;
      case 1:
         query = tkBatchPriority;
        break;
      case 2:
        query = pratBatchPriority;
        break;
      case 3:
        query = pratBatchBackground;
        break;
      case 4:
        query = rinnoviAssenso;
        break;
     default:
        query = nil;
        NSLog(@"Unexpected query index");
        break;
    }
  if (query)
    {
      switch ([limitSelector indexOfSelectedItem])
        {
        case 0:
          query = [query stringByAppendingString:@" LIMIT 1"];
          break;
        case 1:
          query = [query stringByAppendingString:@" LIMIT 10"];
          break;
        case 2:
          query = [query stringByAppendingString:@" LIMIT 100"];
          break;
        default:
          break;
        }
    }

  [query retain];
  [countField setStringValue:@""];
  [logger log: LogStandard :@"[QueryCacher] Query: %@\n", query];
  iteration = 1;
  done = NO;
  wentTimeOut = NO;
  while (!done)
    {
      NS_DURING
        {
          wentTimeOut = NO;
          resArray = [dbs queryFull :query queryAll:NO  progressMonitor:self];
          [resArray retain];
        }
      NS_HANDLER
        {
          if ([[localException name] hasPrefix:@"DB"])
            {
              [logger log: LogStandard :@"[QueryCacher] %@\n", [localException reason]];
              NSLog(@"Exception reason: %@", [localException reason]);
              NSLog(@"Exception userInfo: %@", [localException userInfo]);
              if ([[localException reason] isEqualToString:@"Your query request was running for too long."])
                {
                  NSLog(@"Query Timeout!");
                  wentTimeOut = YES;
                }
            }
          else
            {
              NSLog(@"Unexpected exception reason: %@", [localException reason]);
              NSLog(@"Unexpected exception userInfo: %@", [localException userInfo]);
              done = YES;
            }
          resArray = nil;
        }
      NS_ENDHANDLER
       
      if (!done && ([retryButton state] == NSOnState) && wentTimeOut)
        {
          NSLog(@"we should retry");
          if (iteration > 10)
            done = YES;
        }
      else
        done = YES;

      [iterationField setIntValue:iteration];
      iteration++;
    }
  
  if (resArray != nil)
    {
      NSLog(@"executed, return array %@", resArray);
      NSLog(@"query returns: %u", (unsigned int)[resArray count]);
      [countField setIntValue:(NSInteger)[resArray count]];
      [resArray release];
    }
  [query release];
}

/* ---- DBProgressProtocol ---- */

-(void)reset
{
}

-(void)setMaximumValue:(unsigned long)max
{
  [logger log:LogDebug :@"[DBProgress] maximum: %lu\n", max];
}

-(void)setCurrentValue:(unsigned long)current
{
  [logger log:LogDebug :@"[DBProgress] current: %lu\n", current];
}

-(void)incrementCurrentValue:(unsigned long)amount
{
  [logger log:LogDebug :@"[DBProgress] amount: %lu\n", amount];
}

-(void)setEnd
{
  [logger log:LogDebug :@"[DBProgress]: End\n"];
}


-(void)setCurrentDescription:(NSString *)desc
{
  [currProgressField setStringValue:desc];
  [logger log:LogStandard :@"[DBProgress]:[%@]\n", desc];
}

- (BOOL)shouldStop
{
  return NO;
}

- (void)setShouldStop:(BOOL)flag
{
  
}

@end
